/**
 * Notify on Pi completion/attention and mirror agent state in tmux window names.
 *
 * This intentionally uses terminal-notifier instead of Pi's in-TUI notification API
 * so background tmux windows still surface native macOS alerts.
 */

import { execFile, execFileSync, spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

const RUNNING_MARKER = "⚡";
const ATTENTION_MARKER = "🔔";
const NOTIFICATION_SOUND = "Pong";
const NOTIFICATION_DEBOUNCE_MS = 10_000;
// Foreground completions should still give feedback, but not leave stale macOS alerts.
const FOREGROUND_NOTIFICATION_TTL_MS = 5_000;
const KITTY_BUNDLE_ID = "net.kovidgoyal.kitty";
// Match clear-bell.sh so macOS notifications clear when the tmux bell is acknowledged.
const NOTIFICATION_GROUP_PREFIX = "pi-tmux-notify";

const DEFAULT_MESSAGE = "Pi is waiting for input";

let submittedPrompt = DEFAULT_MESSAGE;
let clientName: string | undefined;
let sessionName: string | undefined;
let windowId: string | undefined;
let paneId: string | undefined;
let agentActive = false;
let lastNotificationKey = "";
let lastNotificationAt = 0;

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

function commandPath(command: string): string | undefined {
	try {
		// Resolve through a shell so Homebrew paths from shell startup files are honored;
		// Pi's Node process PATH can be narrower, making execFile("terminal-notifier") fail silently.
		return execFileSync("/usr/bin/env", ["bash", "-lc", `command -v ${shellQuote(command)}`], {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim() || undefined;
	} catch {
		return undefined;
	}
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

function captureTmuxWindow(): void {
	// Store the exact tmux target so notification clicks can return to this Pi pane.
	clientName = tmux("#{client_name}");
	sessionName = tmux("#{session_name}");
	windowId = tmux("#{window_id}");
	paneId = tmux("#{pane_id}");
}

function notificationTitle(): string {
	const session = tmux("#S", windowId);
	const rawWindow = tmux("#W", windowId);
	const window = rawWindow ? cleanWindowName(rawWindow) : undefined;

	if (!session) return "⟫";
	return window ? `${session}  ⧉  ${window}` : session;
}

function isActivePane(target: string | undefined): boolean {
	if (!target) return false;

	// Query the captured pane directly; an untargeted tmux command can resolve to
	// the pane running Pi instead of the pane currently focused by the client.
	return tmux("#{pane_active}:#{window_active}", target) === "1:1";
}

function frontmostBundleId(): string | undefined {
	try {
		return execFileSync(
			"/usr/bin/osascript",
			["-e", 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true'],
			{ encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
		).trim() || undefined;
	} catch {
		return undefined;
	}
}

function isTmuxClientAtCapturedPane(): boolean {
	if (!clientName || !sessionName || !windowId || !paneId) return isActivePane(paneId);
	return tmux("#{session_name}|#{window_id}|#{pane_id}", clientName) === `${sessionName}|${windowId}|${paneId}`;
}

function isUserViewingCapturedPane(): boolean {
	// Auto-clear only when Kitty is frontmost and this tmux client is on the exact Pi pane;
	// if the user is in another app/session/pane, the notification should persist.
	return frontmostBundleId() === KITTY_BUNDLE_ID && isTmuxClientAtCapturedPane();
}

function isBackgroundPane(target: string | undefined): boolean {
	if (!target) return false;

	const focusState = tmux("#{pane_active}:#{window_active}", target);
	return Boolean(focusState && focusState !== "1:1");
}

function setWindowMarker(marker: typeof RUNNING_MARKER | typeof ATTENTION_MARKER | undefined): void {
	if (!process.env.TMUX || !windowId) return;

	const currentName = tmux("#W", windowId);
	if (!currentName) return;

	const cleanName = cleanWindowName(currentName);
	const nextName = marker ? `${cleanName} ${marker}` : cleanName;
	if (currentName !== nextName) renameWindow(windowId, nextName);
}

function markRunning(): void {
	agentActive = true;
	setWindowMarker(RUNNING_MARKER);
}

function markWaitingForAttention(): void {
	if (!windowId) return;
	setWindowMarker(isBackgroundPane(paneId) ? ATTENTION_MARKER : undefined);
}

function notificationGroup(): string | undefined {
	// Re-read as a fallback so notifications stay removable even if startup capture missed tmux.
	const targetWindowId = windowId ?? tmux("#{window_id}");
	return targetWindowId ? `${NOTIFICATION_GROUP_PREFIX}:${targetWindowId}` : undefined;
}

function removeNotificationGroup(group: string): void {
	// Alerter is preferred for actionable notifications; terminal-notifier remains as fallback.
	const alerter = commandPath("alerter");
	if (alerter) execFile(alerter, ["--remove", group], () => {});

	const terminalNotifier = commandPath("terminal-notifier");
	if (terminalNotifier) execFile(terminalNotifier, ["-remove", group], () => {});
}

function removeNotificationGroupSoon(group: string): void {
	// If the Pi pane is already active, auto-acknowledge after a short glance window.
	const timer = setTimeout(() => removeNotificationGroup(group), FOREGROUND_NOTIFICATION_TTL_MS);
	timer.unref();
}

function focusTmuxTarget(): void {
	const tmuxPath = commandPath("tmux");
	const targetClient = clientName ?? tmux("#{client_name}");
	const targetSession = sessionName ?? (windowId ? tmux("#S", windowId) : tmux("#S"));
	const targetWindow = windowId ?? tmux("#{window_id}");
	const targetPane = paneId ?? tmux("#{pane_id}");

	try {
		execFileSync("/usr/bin/open", ["-a", "kitty"], { stdio: "ignore" });
	} catch {}
	if (!tmuxPath) return;

	try {
		if (targetClient && targetSession) {
			execFileSync(tmuxPath, ["switch-client", "-c", targetClient, "-t", targetSession], { stdio: "ignore" });
		} else if (targetSession) {
			execFileSync(tmuxPath, ["switch-client", "-t", targetSession], { stdio: "ignore" });
		}
	} catch {}
	try {
		if (targetWindow) execFileSync(tmuxPath, ["select-window", "-t", targetWindow], { stdio: "ignore" });
	} catch {}
	try {
		if (targetPane) execFileSync(tmuxPath, ["select-pane", "-t", targetPane], { stdio: "ignore" });
	} catch {}
	try {
		// Focus Kitty again after tmux selection in case macOS activation raced the command.
		execFileSync("/usr/bin/open", ["-a", "kitty"], { stdio: "ignore" });
	} catch {}
}

function notifyWithAlerter(
	alerter: string,
	title: string,
	message: string,
	group: string | undefined,
	shouldAutoClear: boolean,
): void {
	const tmuxPath = commandPath("tmux");
	if (!tmuxPath) return;

	// Alerter blocks until the user clicks/dismisses, giving reliable click results
	// on modern macOS where terminal-notifier callbacks no longer fire consistently.
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
				PI_TARGET_CLIENT: clientName ?? "",
				PI_TARGET_SESSION: sessionName ?? "",
				PI_TARGET_WINDOW: windowId ?? "",
				PI_TARGET_PANE: paneId ?? "",
			},
		},
	);
	child.unref();
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
	const alerter = commandPath("alerter");
	if (alerter) {
		notifyWithAlerter(alerter, title, message, group, shouldAutoClear);
		return;
	}

	const terminalNotifier = commandPath("terminal-notifier");
	if (terminalNotifier) {
		const args = ["-title", title, "-message", message, "-sound", NOTIFICATION_SOUND];
		if (group) args.push("-group", group);

		execFile(
			terminalNotifier,
			args,
			(error) => {
				if (!error) {
					if (shouldAutoClear && group) removeNotificationGroupSoon(group);
					return;
				}
				notifyWithOsaScript(title, message);
			},
		);
		return;
	}

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
		captureTmuxWindow();
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
