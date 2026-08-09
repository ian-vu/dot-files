/**
 * Auto idle shutdown for long-lived Pi sessions.
 *
 * Idle terminal panes can keep separate Pi Node runtimes alive for days. This
 * extension exits only the current Pi process after sustained inactivity, while
 * printing an exact command that resumes the saved session.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const EXTENSION_NAME = "auto-idle-shutdown";
const STATE_ENTRY_TYPE = "auto-idle-shutdown-state";
const DEFAULT_IDLE_LIMIT_MS = 3 * 60 * 60 * 1000; // 3 hours
const DEFAULT_CHECK_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

let startedAt = Date.now();
let lastActivityAt = Date.now();
let lastActivityReason = "extension loaded";
let disabled = false;
let pinned = false;
let shuttingDown = false;
let latestContext: ExtensionContext | undefined;
let checkTimer: NodeJS.Timeout | undefined;
let configuredIdleLimitMs = DEFAULT_IDLE_LIMIT_MS;

export default function (pi: ExtensionAPI) {
	const idleLimitMs = readDurationEnv("PI_IDLE_SHUTDOWN_MS", DEFAULT_IDLE_LIMIT_MS);
	const checkIntervalMs = readDurationEnv("PI_IDLE_SHUTDOWN_CHECK_MS", DEFAULT_CHECK_INTERVAL_MS);
	configuredIdleLimitMs = idleLimitMs;

	pi.on("session_start", async (_event, ctx) => {
		latestContext = ctx;
		startedAt = Date.now();
		lastActivityAt = Date.now();
		lastActivityReason = "session_start";
		shuttingDown = false;
		restorePinnedState(ctx);
		installTimer(pi, ctx, idleLimitMs, checkIntervalMs);
		setStatus(ctx, idleLimitMs);
	});

	pi.on("input", async () => markActivity("input"));
	pi.on("user_bash", async () => markActivity("user_bash"));
	pi.on("before_agent_start", async () => markActivity("before_agent_start"));
	pi.on("agent_start", async () => markActivity("agent_start"));
	pi.on("agent_end", async () => markActivity("agent_end"));
	pi.on("turn_start", async () => markActivity("turn_start"));
	pi.on("turn_end", async () => markActivity("turn_end"));
	pi.on("message_start", async () => markActivity("message_start"));
	pi.on("message_end", async () => markActivity("message_end"));
	pi.on("tool_execution_start", async () => markActivity("tool_execution_start"));
	pi.on("tool_execution_end", async () => markActivity("tool_execution_end"));
	pi.on("tool_call", async () => markActivity("tool_call"));
	pi.on("tool_result", async () => markActivity("tool_result"));
	pi.on("model_select", async () => markActivity("model_select"));
	pi.on("thinking_level_select", async () => markActivity("thinking_level_select"));

	pi.on("session_shutdown", async (_event, ctx) => {
		if (checkTimer) clearInterval(checkTimer);
		checkTimer = undefined;
		if (ctx.hasUI) ctx.ui.setStatus(EXTENSION_NAME, undefined);
	});

	pi.registerCommand("idle-shutdown", {
		description: "Manage auto shutdown for Pi sessions idle for a day",
		handler: async (args, ctx) => {
			latestContext = ctx;
			const action = args.trim().split(/\s+/, 1)[0] || "status";

			switch (action) {
				case "status":
					showStatus(ctx, idleLimitMs, checkIntervalMs);
					break;
				case "enable":
					disabled = false;
					setStatus(ctx, idleLimitMs);
					ctx.ui.notify("Auto idle shutdown enabled", "info");
					break;
				case "disable":
					disabled = true;
					setStatus(ctx, idleLimitMs);
					ctx.ui.notify("Auto idle shutdown disabled for this process", "warning");
					break;
				case "pin":
					pinned = true;
					pi.appendEntry(STATE_ENTRY_TYPE, { pinned: true, updatedAt: new Date().toISOString() });
					setStatus(ctx, idleLimitMs);
					ctx.ui.notify("Session pinned; idle shutdown will not exit it", "info");
					break;
				case "unpin":
					pinned = false;
					pi.appendEntry(STATE_ENTRY_TYPE, { pinned: false, updatedAt: new Date().toISOString() });
					setStatus(ctx, idleLimitMs);
					ctx.ui.notify("Session unpinned", "info");
					break;
				case "now":
					await shutdownWithNotice(pi, ctx, idleLimitMs, "manual /idle-shutdown now");
					break;
				default:
					ctx.ui.notify("Usage: /idle-shutdown [status|enable|disable|pin|unpin|now]", "warning");
			}
		},
	});
}

function installTimer(pi: ExtensionAPI, ctx: ExtensionContext, idleLimitMs: number, checkIntervalMs: number): void {
	if (checkTimer) clearInterval(checkTimer);

	// The timer is intentionally coarse: it avoids keeping otherwise idle Pi
	// sessions busy while still reclaiming day-old abandoned processes.
	checkTimer = setInterval(() => {
		void checkIdleAndShutdown(pi, latestContext ?? ctx, idleLimitMs);
	}, checkIntervalMs);
	checkTimer.unref?.();
}

async function checkIdleAndShutdown(pi: ExtensionAPI, ctx: ExtensionContext, idleLimitMs: number): Promise<void> {
	if (shuttingDown || disabled || pinned) return;
	if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
	if (ctx.hasUI && ctx.ui.getEditorText().trim().length > 0) return;

	const idleForMs = Date.now() - lastActivityAt;
	if (idleForMs < idleLimitMs) {
		setStatus(ctx, idleLimitMs);
		return;
	}

	await shutdownWithNotice(pi, ctx, idleLimitMs, "idle timeout");
}

async function shutdownWithNotice(pi: ExtensionAPI, ctx: ExtensionContext, idleLimitMs: number, reason: string): Promise<void> {
	if (shuttingDown) return;
	shuttingDown = true;

	const metadata = buildShutdownMetadata(ctx, idleLimitMs, reason);
	const notice = formatShutdownNotice(metadata);

	// Use both a visible custom message and stdout. The custom message is saved in
	// the session; console output gives the terminal a plain resume line at exit.
	try {
		pi.sendMessage({ customType: EXTENSION_NAME, content: notice, display: true, details: metadata });
	} catch {}

	try {
		console.log(`\n${notice}\n`);
	} catch {}

	try {
		ctx.ui.notify("Pi idle shutdown: resume command printed above", "warning");
	} catch {}

	try {
		latestContext = ctx;
		ctx.shutdown();
	} catch {
		process.exitCode = 0;
		process.kill(process.pid, "SIGTERM");
	}
}

function markActivity(reason: string): void {
	if (shuttingDown) return;
	lastActivityAt = Date.now();
	lastActivityReason = reason;
	if (latestContext) setStatus(latestContext, configuredIdleLimitMs);
}

function restorePinnedState(ctx: ExtensionContext): void {
	const entries = ctx.sessionManager.getBranch();
	for (const entry of entries) {
		if (entry.type !== "custom" || entry.customType !== STATE_ENTRY_TYPE) continue;
		const data = entry.data as { pinned?: unknown } | undefined;
		if (typeof data?.pinned === "boolean") pinned = data.pinned;
	}
}

function showStatus(ctx: ExtensionContext, idleLimitMs: number, checkIntervalMs: number): void {
	const metadata = buildShutdownMetadata(ctx, idleLimitMs, "status");
	const lines = [
		"Auto idle shutdown status",
		`state: ${disabled ? "disabled" : pinned ? "pinned" : "enabled"}`,
		`pid: ${metadata.pid}`,
		`idleFor: ${metadata.idleFor}`,
		`idleLimit: ${metadata.idleLimit}`,
		`checkEvery: ${formatDuration(checkIntervalMs)}`,
		`lastActivity: ${metadata.lastActivityAt} (${metadata.lastActivityReason})`,
		`session: ${metadata.sessionFile ?? "<ephemeral>"}`,
		`resume: ${metadata.resumeCommand}`,
	];
	ctx.ui.notify(lines.join("\n"), "info");
}

function setStatus(ctx: ExtensionContext, idleLimitMs: number): void {
	if (!ctx.hasUI) return;
	const state = disabled ? "off" : pinned ? "pinned" : `idle ${formatDuration(Date.now() - lastActivityAt)}/${formatDuration(idleLimitMs)}`;
	ctx.ui.setStatus(EXTENSION_NAME, state);
}

type ShutdownMetadata = {
	reason: string;
	pid: number;
	ppid: number;
	cwd: string;
	mode: string;
	sessionId?: string;
	sessionName?: string;
	sessionFile?: string;
	leafId?: string;
	entries: number;
	model?: string;
	startedAt: string;
	lastActivityAt: string;
	lastActivityReason: string;
	idleFor: string;
	uptime: string;
	idleLimit: string;
	resumeCommand: string;
};

function buildShutdownMetadata(ctx: ExtensionContext, idleLimitMs: number, reason: string): ShutdownMetadata {
	const sessionFile = ctx.sessionManager.getSessionFile();
	const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;

	return {
		reason,
		pid: process.pid,
		ppid: process.ppid,
		cwd: ctx.cwd,
		mode: contextMode(ctx),
		sessionId: ctx.sessionManager.getSessionId(),
		sessionName: ctx.sessionManager.getSessionName(),
		sessionFile,
		leafId: ctx.sessionManager.getLeafId() ?? undefined,
		entries: ctx.sessionManager.getEntries().length,
		model,
		startedAt: new Date(startedAt).toISOString(),
		lastActivityAt: new Date(lastActivityAt).toISOString(),
		lastActivityReason,
		idleFor: formatDuration(Date.now() - lastActivityAt),
		uptime: formatDuration(Date.now() - startedAt),
		idleLimit: formatDuration(idleLimitMs),
		resumeCommand: resumeCommand(ctx.cwd, sessionFile, ctx.sessionManager.getSessionId()),
	};
}

function formatShutdownNotice(metadata: ShutdownMetadata): string {
	return [
		"[pi-auto-idle-shutdown]",
		`reason: ${metadata.reason}`,
		`pid: ${metadata.pid}`,
		`ppid: ${metadata.ppid}`,
		`cwd: ${metadata.cwd}`,
		`mode: ${metadata.mode}`,
		`sessionId: ${metadata.sessionId ?? "<none>"}`,
		`sessionName: ${metadata.sessionName ?? "<unnamed>"}`,
		`sessionFile: ${metadata.sessionFile ?? "<ephemeral>"}`,
		`leafId: ${metadata.leafId ?? "<none>"}`,
		`entries: ${metadata.entries}`,
		`model: ${metadata.model ?? "<unknown>"}`,
		`startedAt: ${metadata.startedAt}`,
		`lastActivityAt: ${metadata.lastActivityAt}`,
		`lastActivityReason: ${metadata.lastActivityReason}`,
		`idleFor: ${metadata.idleFor}`,
		`uptime: ${metadata.uptime}`,
		"resume:",
		`  ${metadata.resumeCommand}`,
	].join("\n");
}

function resumeCommand(cwd: string, sessionFile: string | undefined, sessionId: string | undefined): string {
	if (sessionFile) return `cd ${shellQuote(cwd)} && pi --session ${shellQuote(sessionFile)}`;
	if (sessionId) return `cd ${shellQuote(cwd)} && pi --session ${shellQuote(sessionId)}`;
	return `cd ${shellQuote(cwd)} && pi -c`;
}

function contextMode(ctx: ExtensionContext): string {
	// Older Pi type packages did not expose ctx.mode even though newer runtime docs
	// include it, so read it defensively for cross-version extension loading.
	return (ctx as ExtensionContext & { mode?: string }).mode ?? "unknown";
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

function readDurationEnv(name: string, fallback: number): number {
	const raw = process.env[name];
	if (!raw) return fallback;
	const value = Number(raw);
	return Number.isFinite(value) && value > 0 ? value : fallback;
}

function formatDuration(ms: number): string {
	const totalSeconds = Math.max(0, Math.floor(ms / 1000));
	const days = Math.floor(totalSeconds / 86_400);
	const hours = Math.floor((totalSeconds % 86_400) / 3_600);
	const minutes = Math.floor((totalSeconds % 3_600) / 60);
	const seconds = totalSeconds % 60;

	const parts: string[] = [];
	if (days) parts.push(`${days}d`);
	if (hours || parts.length) parts.push(`${hours}h`);
	if (minutes || parts.length) parts.push(`${minutes}m`);
	if (!parts.length) parts.push(`${seconds}s`);
	return parts.join(" ");
}
