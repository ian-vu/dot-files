/**
 * Notify on Pi completion/attention and mirror agent state in tmux window names.
 *
 * This intentionally uses terminal-notifier instead of Pi's in-TUI notification API
 * so background tmux windows still surface native macOS alerts.
 */

import { execFile, execFileSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

const RUNNING_MARKER = "⚡";
const ATTENTION_MARKER = "🔔";
const NOTIFICATION_SOUND = "Pong";
const NOTIFICATION_DEBOUNCE_MS = 10_000;

const DEFAULT_MESSAGE = "Pi is waiting for input";

let submittedPrompt = DEFAULT_MESSAGE;
let windowId: string | undefined;
let agentActive = false;
let lastNotificationKey = "";
let lastNotificationAt = 0;

function commandExists(command: string): boolean {
	try {
		execFileSync("/usr/bin/env", ["bash", "-lc", `command -v ${command}`], { stdio: "ignore" });
		return true;
	} catch {
		return false;
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
	windowId = tmux("#{window_id}");
}

function notificationTitle(): string {
	const session = tmux("#S", windowId);
	const rawWindow = tmux("#W", windowId);
	const window = rawWindow ? cleanWindowName(rawWindow) : undefined;

	if (!session) return "⟫";
	return window ? `${session}  ⧉  ${window}` : session;
}

function isBackgroundWindow(target: string): boolean {
	const activeWindow = tmux("#{window_id}");
	return Boolean(activeWindow && target !== activeWindow);
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
	setWindowMarker(isBackgroundWindow(windowId) ? ATTENTION_MARKER : undefined);
}

function notify(reason: "complete" | "attention"): void {
	if (!commandExists("terminal-notifier")) return;

	const title = notificationTitle();
	const message = submittedPrompt || DEFAULT_MESSAGE;
	const key = `${reason}\0${title}\0${message}`;
	const now = Date.now();

	// Avoid duplicate alerts from closely spaced attention/completion paths.
	if (key === lastNotificationKey && now - lastNotificationAt < NOTIFICATION_DEBOUNCE_MS) return;
	lastNotificationKey = key;
	lastNotificationAt = now;

	execFile(
		"terminal-notifier",
		["-title", title, "-message", message, "-sound", NOTIFICATION_SOUND],
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
