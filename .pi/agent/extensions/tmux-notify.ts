/**
 * Notify on Pi completion/attention and mirror agent state in tmux window names.
 *
 * Alerter is preferred over terminal-notifier because modern macOS no longer
 * reliably runs terminal-notifier click callbacks. terminal-notifier remains as
 * a fallback because it is still useful for simple grouped notifications.
 */

import { execFile, execFileSync, spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

const RUNNING_MARKER = "⚡";
const ATTENTION_MARKER = "🔔";
const NOTIFICATION_SOUND = "Pong";
const NOTIFICATION_DEBOUNCE_MS = 10_000;
// Foreground completions should give feedback without leaving stale alerts.
const FOREGROUND_NOTIFICATION_TTL_MS = 5_000;
const KITTY_BUNDLE_ID = "net.kovidgoyal.kitty";
// Keep in sync with clear-bell.sh so tmux focus hooks can acknowledge alerts.
const NOTIFICATION_GROUP_PREFIX = "pi-tmux-notify";

const DEFAULT_MESSAGE = "Pi is waiting for input";

type TmuxTarget = {
	clientName?: string;
	sessionName?: string;
	windowId?: string;
	paneId?: string;
};

let submittedPrompt = DEFAULT_MESSAGE;
let tmuxTarget: TmuxTarget = {};
let agentActive = false;
let lastNotificationKey = "";
let lastNotificationAt = 0;

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

function commandPath(command: string): string | undefined {
	try {
		// Resolve through the user's shell path because Pi's Node process often lacks
		// Homebrew paths, which would otherwise make notification helpers disappear.
		return execFileSync("/usr/bin/env", ["bash", "-lc", `command -v ${shellQuote(command)}`], {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim() || undefined;
	} catch {
		return undefined;
	}
}

function runDetached(command: string, args: string[]): void {
	try {
		execFile(command, args, () => {});
	} catch {}
}

function tmux(format: string, target?: string): string | undefined {
	if (!process.env.TMUX) return undefined;

	try {
		const args = target
			? ["display-message", "-t", target, "-p", format]
			: ["display-message", "-p", format];
		return execFileSync("tmux", args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
	} catch {
		return undefined;
	}
}

function tmuxForClient(format: string, targetClient?: string): string | undefined {
	if (!process.env.TMUX) return undefined;

	try {
		const args = targetClient
			? ["display-message", "-c", targetClient, "-p", format]
			: ["display-message", "-p", format];
		return execFileSync("tmux", args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
	} catch {
		return undefined;
	}
}

function renameWindow(target: string, name: string): void {
	try {
		execFileSync("tmux", ["rename-window", "-t", target, name], { stdio: "ignore" });
	} catch {
		// tmux may disappear while Pi is shutting down; notification should still work.
	}
}

function cleanWindowName(name: string): string {
	return name.replace(new RegExp(` (${RUNNING_MARKER}|${ATTENTION_MARKER})$`), "");
}

function captureTmuxTarget(): void {
	// Capture the exact client/session/window/pane at agent start so a later
	// notification click can restore the user to this Pi pane, even after they
	// move to another session or macOS workspace.
	tmuxTarget = {
		clientName: tmuxForClient("#{client_name}"),
		sessionName: tmux("#{session_name}"),
		windowId: tmux("#{window_id}"),
		paneId: tmux("#{pane_id}"),
	};
}

function notificationTitle(): string {
	const session = tmux("#S", tmuxTarget.windowId);
	const rawWindow = tmux("#W", tmuxTarget.windowId);
	const window = rawWindow ? cleanWindowName(rawWindow) : undefined;

	if (!session) return "⟫";
	return window ? `${session}  ⧉  ${window}` : session;
}

function frontmostBundleId(): string | undefined {
	try {
		// The foreground auto-clear must consider macOS focus, not just tmux focus;
		// otherwise alerts would vanish while the user is looking at another app.
		return execFileSync(
			"/usr/bin/osascript",
			["-e", 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true'],
			{ encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
		).trim() || undefined;
	} catch {
		return undefined;
	}
}

function capturedTargetKey(): string | undefined {
	const { sessionName, windowId, paneId } = tmuxTarget;
	return sessionName && windowId && paneId ? `${sessionName}|${windowId}|${paneId}` : undefined;
}

function currentClientTargetKey(): string | undefined {
	return tmuxForClient("#{session_name}|#{window_id}|#{pane_id}", tmuxTarget.clientName);
}

function isTmuxClientAtCapturedPane(): boolean {
	const targetKey = capturedTargetKey();
	return Boolean(targetKey && currentClientTargetKey() === targetKey);
}

function isUserViewingCapturedPane(): boolean {
	return frontmostBundleId() === KITTY_BUNDLE_ID && isTmuxClientAtCapturedPane();
}

function setWindowMarker(marker: typeof RUNNING_MARKER | typeof ATTENTION_MARKER | undefined): void {
	if (!process.env.TMUX || !tmuxTarget.windowId) return;

	const currentName = tmux("#W", tmuxTarget.windowId);
	if (!currentName) return;

	const cleanName = cleanWindowName(currentName);
	const nextName = marker ? `${cleanName} ${marker}` : cleanName;
	if (currentName !== nextName) renameWindow(tmuxTarget.windowId, nextName);
}

function markRunning(): void {
	agentActive = true;
	setWindowMarker(RUNNING_MARKER);
}

function markWaitingForAttention(): void {
	if (!tmuxTarget.windowId) return;
	// Use the captured client, not pane-local active flags, because pane/window can
	// remain "active" inside a session while the client is viewing another session.
	setWindowMarker(isTmuxClientAtCapturedPane() ? undefined : ATTENTION_MARKER);
}

function notificationGroup(): string | undefined {
	// Re-read as a fallback so notifications remain removable if startup capture missed tmux.
	const targetWindowId = tmuxTarget.windowId ?? tmux("#{window_id}");
	return targetWindowId ? `${NOTIFICATION_GROUP_PREFIX}:${targetWindowId}` : undefined;
}

function removeNotificationGroup(group: string): void {
	const alerter = commandPath("alerter");
	if (alerter) runDetached(alerter, ["--remove", group]);

	const terminalNotifier = commandPath("terminal-notifier");
	if (terminalNotifier) runDetached(terminalNotifier, ["-remove", group]);
}

function removeNotificationGroupSoon(group: string): void {
	const timer = setTimeout(() => removeNotificationGroup(group), FOREGROUND_NOTIFICATION_TTL_MS);
	timer.unref();
}

function spawnAlerterNotification(
	alerter: string,
	tmuxPath: string,
	title: string,
	message: string,
	group: string | undefined,
	shouldAutoClear: boolean,
): void {
	// Alerter blocks until the user clicks/dismisses, so run it detached. Its JSON
	// result lets us distinguish Open/content-click from Dismiss/timeout without
	// unreliable terminal-notifier callback hooks.
	const child = spawn(
		"/usr/bin/env",
		[
			"bash",
			"-lc",
			`
				args=(--title "$PI_TITLE" --message "$PI_MESSAGE" --close-label Dismiss --actions Open --json)
				[ -n "$PI_NOTIFY_GROUP" ] && args+=(--group "$PI_NOTIFY_GROUP")
				[ -n "$PI_SOUND" ] && args+=(--sound "$PI_SOUND")
				[ "$PI_AUTO_CLEAR" = 1 ] && args+=(--timeout "$PI_FOREGROUND_TTL_SECONDS")

				result=$("$PI_ALERTER" "\${args[@]}" 2>/dev/null || true)
				if printf '%s' "$result" | /usr/bin/grep -Eq '"activationType"[[:space:]]*:[[:space:]]*"(contentsClicked|actionClicked)"'; then
					/usr/bin/open -a kitty >/dev/null 2>&1 || true
					if [ -n "$PI_TARGET_CLIENT" ] && [ -n "$PI_TARGET_SESSION" ]; then
						"$PI_TMUX" switch-client -c "$PI_TARGET_CLIENT" -t "$PI_TARGET_SESSION" >/dev/null 2>&1 || true
					elif [ -n "$PI_TARGET_SESSION" ]; then
						"$PI_TMUX" switch-client -t "$PI_TARGET_SESSION" >/dev/null 2>&1 || true
					fi
					[ -n "$PI_TARGET_WINDOW" ] && "$PI_TMUX" select-window -t "$PI_TARGET_WINDOW" >/dev/null 2>&1 || true
					[ -n "$PI_TARGET_PANE" ] && "$PI_TMUX" select-pane -t "$PI_TARGET_PANE" >/dev/null 2>&1 || true
					/usr/bin/open -a kitty >/dev/null 2>&1 || true
				fi
			`.replace(/^\t{4}/gm, ""),
		],
		{
			detached: true,
			stdio: "ignore",
			env: {
				...process.env,
				PI_ALERTER: alerter,
				PI_TMUX: tmuxPath,
				PI_TITLE: title,
				PI_MESSAGE: message,
				PI_SOUND: NOTIFICATION_SOUND,
				PI_NOTIFY_GROUP: group ?? "",
				PI_AUTO_CLEAR: shouldAutoClear ? "1" : "0",
				PI_FOREGROUND_TTL_SECONDS: String(Math.ceil(FOREGROUND_NOTIFICATION_TTL_MS / 1000)),
				PI_TARGET_CLIENT: tmuxTarget.clientName ?? "",
				PI_TARGET_SESSION: tmuxTarget.sessionName ?? "",
				PI_TARGET_WINDOW: tmuxTarget.windowId ?? "",
				PI_TARGET_PANE: tmuxTarget.paneId ?? "",
			},
		},
	);
	child.unref();
}

function notifyWithAlerter(title: string, message: string, group: string | undefined, shouldAutoClear: boolean): boolean {
	const alerter = commandPath("alerter");
	const tmuxPath = commandPath("tmux");
	if (!alerter || !tmuxPath) return false;

	spawnAlerterNotification(alerter, tmuxPath, title, message, group, shouldAutoClear);
	return true;
}

function notifyWithTerminalNotifier(title: string, message: string, group: string | undefined, shouldAutoClear: boolean): boolean {
	const terminalNotifier = commandPath("terminal-notifier");
	if (!terminalNotifier) return false;

	const args = ["-title", title, "-message", message, "-sound", NOTIFICATION_SOUND];
	if (group) args.push("-group", group);

	execFile(terminalNotifier, args, (error) => {
		if (error) {
			notifyWithOsaScript(title, message);
			return;
		}
		if (shouldAutoClear && group) removeNotificationGroupSoon(group);
	});
	return true;
}

function notify(reason: "complete" | "attention"): void {
	const title = notificationTitle();
	const message = submittedPrompt || DEFAULT_MESSAGE;
	const key = `${reason}\0${title}\0${message}`;
	const now = Date.now();

	// Avoid duplicate alerts from closely spaced attention/completion paths.
	if (key === lastNotificationKey && now - lastNotificationAt < NOTIFICATION_DEBOUNCE_MS) return;
	lastNotificationKey = key;
	lastNotificationAt = now;

	const group = notificationGroup();
	const shouldAutoClear = Boolean(group && isUserViewingCapturedPane());
	if (notifyWithAlerter(title, message, group, shouldAutoClear)) return;
	if (notifyWithTerminalNotifier(title, message, group, shouldAutoClear)) return;

	notifyWithOsaScript(title, message);
}

function notifyWithOsaScript(title: string, message: string): void {
	execFile(
		"/usr/bin/osascript",
		[
			"-e",
			`display notification ${JSON.stringify(message)} with title ${JSON.stringify(title)} sound name ${JSON.stringify(NOTIFICATION_SOUND)}`,
		],
		() => {},
	);
}

function commandLooksLikeGitPush(command: string): boolean {
	// Mirrors the Claude Code permission gate `Bash(git push:*)` for Pi's bash tool.
	return /(?:^|[;&|()\n])\s*git\s+push\b/.test(command);
}

export default function (pi: ExtensionAPI) {
	pi.on("input", async (event) => {
		submittedPrompt = event.text.trim() || submittedPrompt;
	});

	pi.on("before_agent_start", async (event) => {
		// `input` stores the raw submitted prompt; this fallback covers non-interactive/RPC starts.
		if (submittedPrompt === DEFAULT_MESSAGE) {
			submittedPrompt = event.prompt.trim() || DEFAULT_MESSAGE;
		}
		captureTmuxTarget();
		markRunning();
	});

	pi.on("tool_execution_start", async () => {
		markRunning();
	});

	pi.on("tool_call", async (event, ctx) => {
		markRunning();

		if (!isToolCallEventType("bash", event)) return;
		const command = event.input.command ?? "";
		if (!commandLooksLikeGitPush(command)) return;

		markWaitingForAttention();
		notify("attention");

		if (!ctx.hasUI) {
			return { block: true, reason: "Blocked git push because Pi has no interactive UI to confirm it." };
		}

		const allowed = await ctx.ui.confirm("Allow git push?", command);
		if (!allowed) {
			return { block: true, reason: "User rejected git push." };
		}

		markRunning();
	});

	pi.on("agent_end", async () => {
		agentActive = false;
		markWaitingForAttention();
		notify("complete");
	});

	pi.on("session_shutdown", async () => {
		// Clear only stale running markers. Completed background sessions keep 🔔
		// until the user visits the window, matching the Claude hook behavior.
		if (agentActive) setWindowMarker(undefined);
	});
}
