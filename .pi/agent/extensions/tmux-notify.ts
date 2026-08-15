/**
 * Notify on Pi completion/attention and mirror agent state in tmux window names.
 *
 * Alerter is preferred for actionable grouped notifications. osascript remains
 * as the last-resort fallback when alerter is unavailable.
 *
 * All tmux/osascript side effects run through an async serial queue. Each
 * process spawn costs ~50ms on macOS from Node, and a turn triggers around ten
 * of them; synchronous spawns would block the event loop (freezing the TUI) and
 * add ~1s of wall time to `pi -p` runs. Async spawns keep the event loop free,
 * the queue preserves ordering between marker updates, and independent queries
 * within one step run in parallel.
 */

import { execFile, spawn } from "node:child_process";
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { promisify } from "node:util";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);

const RUNNING_MARKER = "⚡";
const ATTENTION_MARKER = "🔔";
const NOTIFICATION_SOUND = "Pong";
const NOTIFICATION_DEBOUNCE_MS = 10_000;
// Foreground completions should give feedback without leaving stale alerts.
const FOREGROUND_NOTIFICATION_TTL_MS = 5_000;
const KITTY_BUNDLE_ID = "net.kovidgoyal.kitty";
// Keep in sync with clear-bell.sh so tmux focus hooks can acknowledge alerts.
const NOTIFICATION_GROUP_PREFIX = "pi-tmux-notify";
const PENDING_PANES_OPTION = "@pi_tmux_notify_panes";
const NOTIFICATION_ENV_VAR = "PI_TMUX_NOTIFY";
// Store slash-command state outside the stowed dotfiles tree so runtime toggles
// do not dirty the dotfiles repo.
const NOTIFICATION_STATE_PATH = join(
  process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"),
  "pi",
  "tmux-notify.json",
);
const ENABLED_NOTIFICATION_VALUES = new Set([
  "1",
  "true",
  "yes",
  "on",
  "enable",
  "enabled",
]);
const DISABLED_NOTIFICATION_VALUES = new Set([
  "0",
  "false",
  "no",
  "off",
  "disable",
  "disabled",
]);

const ATTENTION_MESSAGE = "Pi needs attention";
const ASK_USER_PROMPT_EVENT = "rpiv:ask-user:prompt";

// tmux-sidebar status protocol: one JSON file per Pi pane under /tmp that the
// sidebar TUI (~/.local/bin/tmux-sidebar.py) polls every second. "running" /
// "waiting" / "done" are the pushed states; idle is the absence of a file.
// clear-bell.sh deletes the file on pane focus, so the sidebar's ✓ and the
// window 🔔 always clear at the same moment.
const SIDEBAR_STATUS_DIR = "/tmp/tmux-sidebar";
type SidebarState = "running" | "waiting" | "done";

type TmuxTarget = {
  clientName?: string;
  sessionName?: string;
  windowId?: string;
  paneId?: string;
};

let latestAssistantSnippet = "✓";
let tmuxTarget: TmuxTarget = {};
let agentActive = false;
let lastNotificationKey = "";
let lastNotificationAt = 0;
let notificationSequence = 0;
let nativeNotificationsEnabled = readNativeNotificationsEnabled();

// Serial queue for tmux/notification side effects. Handlers enqueue work and
// return immediately so the agent turn is never delayed; the queue preserves
// ordering between marker updates that read-modify-write shared tmux state
// (window names, pending-pane options).
let sideEffectQueue: Promise<void> = Promise.resolve();

function enqueueSideEffect(task: () => Promise<void>): void {
  sideEffectQueue = sideEffectQueue.then(task, task).catch(() => {});
}

// Track the last written sidebar state so heartbeat-style events (every tool
// call fires tool_execution_start) do not rewrite the file: `ts` must be the
// state-change timestamp the sidebar uses for its elapsed-time label.
let lastSidebarState: SidebarState | undefined;

function sidebarStatusPath(): string | undefined {
  const paneId = tmuxTarget.paneId ?? process.env.TMUX_PANE;
  if (!paneId) return undefined;
  // Strip the % so file names are shell-safe (%12 → 12.json).
  return join(SIDEBAR_STATUS_DIR, `${paneId.replace(/^%/, "")}.json`);
}

function writeSidebarStatus(state: SidebarState): void {
  const path = sidebarStatusPath();
  if (!path) return;
  if (state === lastSidebarState) return;
  lastSidebarState = state;
  try {
    mkdirSync(SIDEBAR_STATUS_DIR, { recursive: true, mode: 0o700 });
    writeFileSync(
      path,
      `${JSON.stringify({
        session: tmuxTarget.sessionName ?? "",
        pane_id: tmuxTarget.paneId ?? process.env.TMUX_PANE ?? "",
        state,
        pid: process.pid,
        ts: Math.floor(Date.now() / 1000),
      })}\n`,
      "utf8",
    );
  } catch {}
}

function deleteSidebarStatus(): void {
  lastSidebarState = undefined;
  const path = sidebarStatusPath();
  if (!path) return;
  try {
    rmSync(path, { force: true });
  } catch {}
}

export default function (pi: ExtensionAPI) {
  registerNotificationCommand(pi);

  // agentActive stays in sync synchronously so session_shutdown always sees
  // the correct state; the spawn-heavy work goes through the queue.
  pi.on("before_agent_start", async () => {
    agentActive = true;
    enqueueSideEffect(async () => {
      await captureTmuxTarget();
      await markRunning(true);
      writeSidebarStatus("running");
    });
  });

  pi.on("tool_execution_start", async () => {
    agentActive = true;
    enqueueSideEffect(async () => {
      await markRunning();
      // Flips a pending "waiting" back to "running" once the answered question
      // lets the turn continue; a no-op while already running.
      writeSidebarStatus("running");
    });
  });

  pi.on("tool_execution_end", async (event) => {
    // ask_user_question's tool_execution_start writes "running" and the prompt
    // event then overrides it with "waiting". The tool only ends once the user
    // submits an answer, so flip ❗ back to ⚡ here - otherwise the sidebar stays
    // on "waiting" through the agent's post-answer thinking until the next
    // tool_execution_start fires (which may never happen if the turn ends with
    // a text response).
    if (event.toolName !== "ask_user_question") return;
    agentActive = true;
    enqueueSideEffect(async () => {
      await markRunning();
      writeSidebarStatus("running");
    });
  });

  pi.on("message_end", async (event) => {
    if (event.message.role !== "assistant") return;
    latestAssistantSnippet =
      assistantMessageSnippet(event.message) || latestAssistantSnippet;
  });

  pi.events.on(ASK_USER_PROMPT_EVENT, () => {
    enqueueSideEffect(async () => {
      // A pending question means Pi is blocked on the user: the sidebar shows
      // ❗ regardless of whether the client is viewing the pane, so write
      // "waiting" here and skip the done/delete handling in the marker path.
      // Reset the dedup guard so each new question resets the sidebar's elapsed
      // timer; without this, a second question asked with no intervening tool
      // (only thinking between answers) would no-op and keep the old timestamp.
      lastSidebarState = undefined;
      writeSidebarStatus("waiting");
      await markWaitingForAttention({ updateSidebar: false });
      await notify("question", askUserPromptMessage());
    });
  });

  // Wait until retries, compaction, and queued follow-ups finish so macOS does
  // not report completion while Pi still has automatic work to do. The local
  // editor types lag the runtime version that added agent_settled.
  const onAgentSettled = pi.on as unknown as (
    event: "agent_settled",
    handler: () => Promise<void>,
  ) => void;
  onAgentSettled("agent_settled", async () => {
    agentActive = false;
    enqueueSideEffect(async () => {
      await markWaitingForAttention();
      await notify("complete", latestAssistantSnippet);
    });
  });

  pi.on("session_shutdown", async () => {
    // Clear only stale running markers. Completed background sessions keep 🔔
    // until the user visits each pane that requested attention. Await the queue
    // so pending marker updates finish before the process exits.
    if (agentActive) {
      enqueueSideEffect(async () => {
        await refreshWindowMarkerFromPendingPanes();
        // A shutdown mid-turn would otherwise leave a permanent ⚡/❗ row.
        deleteSidebarStatus();
      });
    }
    await sideEffectQueue;
  });
}

function registerNotificationCommand(pi: ExtensionAPI): void {
  pi.registerCommand("tmux-notify", {
    description: "Enable, disable, or check native Pi notifications",
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase().split(/\s+/, 1)[0] ?? "";

      if (action === "" || action === "status") {
        notifyNativeNotificationStatus(ctx);
        return;
      }

      if (action === "toggle") {
        setNativeNotificationsEnabled(!nativeNotificationsEnabled);
        notifyNativeNotificationStatus(ctx);
        return;
      }

      if (ENABLED_NOTIFICATION_VALUES.has(action)) {
        setNativeNotificationsEnabled(true);
        notifyNativeNotificationStatus(ctx);
        return;
      }

      if (DISABLED_NOTIFICATION_VALUES.has(action)) {
        setNativeNotificationsEnabled(false);
        ctx.ui.notify(
          "Native Pi notifications disabled; tmux window markers still update.",
          "warning",
        );
        return;
      }

      ctx.ui.notify(
        "Usage: /tmux-notify [status|enable|disable|toggle]",
        "warning",
      );
    },
  });
}

function notifyNativeNotificationStatus(ctx: ExtensionCommandContext): void {
  ctx.ui.notify(
    `Native Pi notifications are ${nativeNotificationsEnabled ? "enabled" : "disabled"}`,
    nativeNotificationsEnabled ? "info" : "warning",
  );
}

function readNativeNotificationsEnabled(): boolean {
  const envValue = process.env[NOTIFICATION_ENV_VAR]?.trim().toLowerCase();
  if (envValue && ENABLED_NOTIFICATION_VALUES.has(envValue)) return true;
  if (envValue && DISABLED_NOTIFICATION_VALUES.has(envValue)) return false;

  try {
    const state = JSON.parse(readFileSync(NOTIFICATION_STATE_PATH, "utf8")) as {
      enabled?: unknown;
    };
    return state.enabled !== false;
  } catch {
    return true;
  }
}

function setNativeNotificationsEnabled(enabled: boolean): void {
  mkdirSync(dirname(NOTIFICATION_STATE_PATH), { recursive: true });
  writeFileSync(
    NOTIFICATION_STATE_PATH,
    `${JSON.stringify({ enabled }, null, "\t")}\n`,
    "utf8",
  );
  nativeNotificationsEnabled = enabled;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

// alerter/tmux install locations do not change within a session, so resolve
// each binary through the user's login shell once and reuse the promise. This
// removes two `bash -lc` spawns from every notification.
const commandPathCache = new Map<string, Promise<string | undefined>>();

function commandPath(command: string): Promise<string | undefined> {
  let cached = commandPathCache.get(command);
  if (!cached) {
    // Resolve through the user's shell path because Pi's Node process often lacks
    // Homebrew paths, which would otherwise make notification helpers disappear.
    cached = execFileAsync("/usr/bin/env", [
      "bash",
      "-lc",
      `command -v ${shellQuote(command)}`,
    ])
      .then(({ stdout }) => stdout.trim() || undefined)
      .catch(() => undefined);
    commandPathCache.set(command, cached);
  }
  return cached;
}

function runDetached(command: string, args: string[]): void {
  try {
    execFile(command, args, () => {});
  } catch {}
}

async function tmux(
  format: string,
  target?: string,
): Promise<string | undefined> {
  if (!process.env.TMUX) return undefined;

  try {
    const args = target
      ? ["display-message", "-t", target, "-p", format]
      : ["display-message", "-p", format];
    const { stdout } = await execFileAsync("tmux", args);
    return stdout.trim();
  } catch {
    return undefined;
  }
}

// Query several tmux formats in one display-message call instead of one spawn
// per field. The unit separator will not appear in session or window names, so
// it is a safe delimiter.
const TMUX_FIELD_SEPARATOR = "\x1f";

async function tmuxBatch(
  formats: string[],
  target?: string,
): Promise<(string | undefined)[]> {
  if (!process.env.TMUX) return formats.map(() => undefined);

  try {
    const query = formats.join(TMUX_FIELD_SEPARATOR);
    const args = target
      ? ["display-message", "-t", target, "-p", query]
      : ["display-message", "-p", query];
    const { stdout } = await execFileAsync("tmux", args);
    const parts = stdout.replace(/\n+$/, "").split(TMUX_FIELD_SEPARATOR);
    // Mirror tmux()'s success semantics: a resolved field is a trimmed string
    // (possibly empty); only a failed spawn yields undefined for every field.
    return formats.map((_, index) => (parts[index] ?? "").trim());
  } catch {
    return formats.map(() => undefined);
  }
}

async function tmuxForClient(
  format: string,
  targetClient?: string,
): Promise<string | undefined> {
  if (!process.env.TMUX) return undefined;

  try {
    const args = targetClient
      ? ["display-message", "-c", targetClient, "-p", format]
      : ["display-message", "-p", format];
    const { stdout } = await execFileAsync("tmux", args);
    return stdout.trim();
  } catch {
    return undefined;
  }
}

async function renameWindow(target: string, name: string): Promise<void> {
  try {
    await execFileAsync("tmux", ["rename-window", "-t", target, name]);
  } catch {
    // tmux may disappear while Pi is shutting down; notification should still work.
  }
}

async function showWindowOption(
  target: string,
  option: string,
): Promise<string> {
  try {
    const { stdout } = await execFileAsync("tmux", [
      "show-option",
      "-wqv",
      "-t",
      target,
      option,
    ]);
    return stdout.trim();
  } catch {
    return "";
  }
}

async function setWindowOption(
  target: string,
  option: string,
  value: string,
): Promise<void> {
  try {
    await execFileAsync("tmux", [
      "set-option",
      "-wq",
      "-t",
      target,
      option,
      value,
    ]);
  } catch {}
}

async function pendingPaneIds(): Promise<string[]> {
  await refreshTmuxTargetFromPane();
  if (!process.env.TMUX || !tmuxTarget.windowId) return [];
  const raw = await showWindowOption(tmuxTarget.windowId, PENDING_PANES_OPTION);
  return raw.split(/\s+/).filter(Boolean);
}

async function setPendingPaneIds(paneIds: string[]): Promise<void> {
  await refreshTmuxTargetFromPane();
  if (!process.env.TMUX || !tmuxTarget.windowId) return;
  await setWindowOption(
    tmuxTarget.windowId,
    PENDING_PANES_OPTION,
    [...new Set(paneIds)].join(" "),
  );
}

async function addPendingPane(): Promise<void> {
  if (!tmuxTarget.paneId) return;
  await setPendingPaneIds([...(await pendingPaneIds()), tmuxTarget.paneId]);
}

async function acknowledgeCapturedPane(): Promise<void> {
  if (!tmuxTarget.paneId) return;
  await setPendingPaneIds(
    (await pendingPaneIds()).filter((paneId) => paneId !== tmuxTarget.paneId),
  );
  await refreshWindowMarkerFromPendingPanes();
}

function cleanWindowName(name: string): string {
  return name.replace(
    new RegExp(` (?:${RUNNING_MARKER}|${ATTENTION_MARKER})+$`),
    "",
  );
}

async function captureTmuxTarget(): Promise<void> {
  // Capture from TMUX_PANE instead of tmux's implicit current client. In attached
  // multi-window setups, untargeted display-message can report a different active
  // pane and make one window acknowledge another window's notification.
  const paneTarget = process.env.TMUX_PANE;
  if (!process.env.TMUX) {
    tmuxTarget = {};
    return;
  }
  const [clientName, sessionName, windowId, paneId] = await tmuxBatch(
    ["#{client_name}", "#{session_name}", "#{window_id}", "#{pane_id}"],
    paneTarget,
  );
  tmuxTarget = {
    clientName: clientName ?? (await tmuxForClient("#{client_name}")),
    sessionName,
    windowId,
    paneId,
  };
  // The batch just resolved a fresh target, so let helpers within this turn skip
  // the pane re-query until the debounce window lapses.
  lastTargetRefreshAt = Date.now();
}

// A single turn calls refreshTmuxTargetFromPane through many helpers; each call
// otherwise spawns tmux. Debouncing collapses those to one query per turn while
// still following a pane moved via `break-pane` on the next turn.
const TARGET_REFRESH_DEBOUNCE_MS = 250;
let lastTargetRefreshAt = 0;

async function refreshTmuxTargetFromPane(): Promise<void> {
  if (!process.env.TMUX || !tmuxTarget.paneId) return;

  const now = Date.now();
  if (now - lastTargetRefreshAt < TARGET_REFRESH_DEBOUNCE_MS) return;
  // Set the timestamp before awaiting so concurrent callers within the debounce
  // window do not all spawn tmux while the first query is still in flight.
  lastTargetRefreshAt = now;

  // A pane can be moved to a new tmux window with `break-pane` (`tmux !`) while
  // Pi is running. Follow the stable pane id so notifications and markers target
  // the pane's current window instead of the window captured at agent start.
  const [sessionName, windowId] = await tmuxBatch(
    ["#{session_name}", "#{window_id}"],
    tmuxTarget.paneId,
  );
  tmuxTarget.sessionName = sessionName ?? tmuxTarget.sessionName;
  tmuxTarget.windowId = windowId ?? tmuxTarget.windowId;
}

async function notificationTitle(): Promise<string> {
  await refreshTmuxTargetFromPane();
  const [session, rawWindow] = await tmuxBatch(
    ["#S", "#W"],
    tmuxTarget.windowId,
  );
  const window = rawWindow ? cleanWindowName(rawWindow) : undefined;

  if (!session) return "⟫";
  return window ? `${session}  ⧉  ${window}` : session;
}

async function frontmostBundleId(): Promise<string | undefined> {
  try {
    // The foreground auto-clear must consider macOS focus, not just tmux focus;
    // otherwise alerts would vanish while the user is looking at another app.
    const { stdout } = await execFileAsync("/usr/bin/osascript", [
      "-e",
      'tell application "System Events" to get bundle identifier of first application process whose frontmost is true',
    ]);
    return stdout.trim() || undefined;
  } catch {
    return undefined;
  }
}

async function capturedTargetKey(): Promise<string | undefined> {
  await refreshTmuxTargetFromPane();
  const { sessionName, windowId, paneId } = tmuxTarget;
  return sessionName && windowId && paneId
    ? `${sessionName}|${windowId}|${paneId}`
    : undefined;
}

function currentClientTargetKey(): Promise<string | undefined> {
  return tmuxForClient(
    "#{session_name}|#{window_id}|#{pane_id}",
    tmuxTarget.clientName,
  );
}

async function isTmuxClientAtCapturedPane(): Promise<boolean> {
  const targetKey = await capturedTargetKey();
  if (!targetKey) return false;
  return (await currentClientTargetKey()) === targetKey;
}

async function isUserViewingCapturedPane(): Promise<boolean> {
  // The osascript focus query (~140ms) and the tmux client query are
  // independent, so run them in parallel.
  const [bundleId, atCapturedPane] = await Promise.all([
    frontmostBundleId(),
    isTmuxClientAtCapturedPane(),
  ]);
  return bundleId === KITTY_BUNDLE_ID && atCapturedPane;
}

async function setWindowMarker(
  marker: typeof RUNNING_MARKER | typeof ATTENTION_MARKER | undefined,
): Promise<void> {
  await refreshTmuxTargetFromPane();
  if (!process.env.TMUX || !tmuxTarget.windowId) return;

  const currentName = await tmux("#W", tmuxTarget.windowId);
  if (!currentName) return;

  const cleanName = cleanWindowName(currentName);
  const nextName = marker ? `${cleanName} ${marker}` : cleanName;
  if (currentName !== nextName)
    await renameWindow(tmuxTarget.windowId, nextName);
}

// tool_execution_start fires for every tool call, but the ⚡ marker only needs
// re-asserting occasionally (it can be wiped by an external rename). Skipping
// re-assertions inside this window cuts two tmux spawns per tool call.
const RUNNING_MARKER_REASSERT_MS = 5_000;
let lastRunningMarkAt = 0;

async function markRunning(force = false): Promise<void> {
  agentActive = true;
  const now = Date.now();
  if (!force && now - lastRunningMarkAt < RUNNING_MARKER_REASSERT_MS) return;
  lastRunningMarkAt = now;
  await setWindowMarker(RUNNING_MARKER);
}

async function refreshWindowMarkerFromPendingPanes(): Promise<void> {
  await setWindowMarker(
    (await pendingPaneIds()).length > 0 ? ATTENTION_MARKER : undefined,
  );
}

async function markWaitingForAttention(
  { updateSidebar = true }: { updateSidebar?: boolean } = {},
): Promise<void> {
  // The next turn must re-assert the running marker immediately.
  lastRunningMarkAt = 0;
  if (!tmuxTarget.windowId) return;
  // Use the captured client, not pane-local active flags, because pane/window can
  // remain "active" inside a session while the client is viewing another session.
  if (await isTmuxClientAtCapturedPane()) {
    await acknowledgeCapturedPane();
    // Auto-acknowledge: the user is already looking at the pane, so no ✓
    // should linger in the sidebar (mirrors the 🔔 auto-ack path).
    if (updateSidebar) deleteSidebarStatus();
  } else {
    await addPendingPane();
    await setWindowMarker(ATTENTION_MARKER);
    // Background completion: ✓ persists until clear-bell.sh removes the file
    // when the pane is focused, exactly like the window 🔔.
    if (updateSidebar) writeSidebarStatus("done");
  }
}

async function notificationGroup(): Promise<string | undefined> {
  // Group by pane, not window: multiple Pi panes in the same window should not
  // replace or clear each other's native notifications.
  const targetPaneId =
    tmuxTarget.paneId ?? process.env.TMUX_PANE ?? (await tmux("#{pane_id}"));
  return targetPaneId
    ? `${NOTIFICATION_GROUP_PREFIX}:${targetPaneId}`
    : undefined;
}

async function removeNotificationGroup(group: string): Promise<void> {
  const alerter = await commandPath("alerter");
  if (alerter) runDetached(alerter, ["--remove", group]);
}

function removeNotificationGroupSoon(group: string, sequence: number): void {
  const timer = setTimeout(() => {
    // Avoid an old foreground auto-clear deleting a newer notification that reused
    // the same pane group shortly after the previous completion.
    if (notificationSequence === sequence) void removeNotificationGroup(group);
  }, FOREGROUND_NOTIFICATION_TTL_MS);
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
        PI_FOREGROUND_TTL_SECONDS: String(
          Math.ceil(FOREGROUND_NOTIFICATION_TTL_MS / 1000),
        ),
        PI_TARGET_CLIENT: tmuxTarget.clientName ?? "",
        PI_TARGET_SESSION: tmuxTarget.sessionName ?? "",
        PI_TARGET_WINDOW: tmuxTarget.windowId ?? "",
        PI_TARGET_PANE: tmuxTarget.paneId ?? "",
      },
    },
  );
  child.unref();
}

async function notifyWithAlerter(
  title: string,
  message: string,
  group: string | undefined,
  shouldAutoClear: boolean,
): Promise<boolean> {
  const [alerter, tmuxPath] = await Promise.all([
    commandPath("alerter"),
    commandPath("tmux"),
  ]);
  if (!alerter || !tmuxPath) return false;

  spawnAlerterNotification(
    alerter,
    tmuxPath,
    title,
    message,
    group,
    shouldAutoClear,
  );
  return true;
}

function askUserPromptMessage(): string {
  // The ❗ emoji makes a pending question stand out from ordinary completion
  // alerts in macOS Notification Center at a glance.
  return "❗ pending question";
}

function assistantMessageSnippet(message: {
  content?: unknown;
}): string | undefined {
  if (!Array.isArray(message.content)) return undefined;

  const text = message.content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const maybeText = (part as { type?: unknown; text?: unknown }).text;
      return typeof maybeText === "string" ? maybeText : "";
    })
    .join("\n")
    .trim();
  if (!text) return undefined;

  return firstResponseLine(text).slice(0, 180) || undefined;
}

function firstResponseLine(text: string): string {
  return (
    text
      .split(/\r?\n/)
      .find((line) => line.trim())
      ?.replace(/\s+/g, " ")
      .trim() ?? ""
  );
}

async function notify(
  reason: "complete" | "attention" | "question",
  messageOverride?: string,
): Promise<void> {
  // Muting native alerts keeps the tmux 🔔 marker path active, so background
  // sessions still advertise that they need attention without macOS popups.
  if (!nativeNotificationsEnabled) return;

  await refreshTmuxTargetFromPane();
  // Title, pane group, and focus state are independent queries; run them in
  // parallel so the slow osascript focus check overlaps the tmux spawns.
  const [title, group, userViewing] = await Promise.all([
    notificationTitle(),
    notificationGroup(),
    reason === "question"
      ? Promise.resolve(false)
      : isUserViewingCapturedPane(),
  ]);
  const message = messageOverride ?? ATTENTION_MESSAGE;
  const key = `${reason}\0${title}\0${message}`;
  const now = Date.now();

  // Avoid duplicate alerts from closely spaced attention/completion paths.
  if (
    key === lastNotificationKey &&
    now - lastNotificationAt < NOTIFICATION_DEBOUNCE_MS
  )
    return;
  lastNotificationKey = key;
  lastNotificationAt = now;

  const shouldAutoClear =
    reason !== "question" && Boolean(group && userViewing);
  const sequence = ++notificationSequence;
  if (await notifyWithAlerter(title, message, group, shouldAutoClear)) return;
  if (shouldAutoClear && group) removeNotificationGroupSoon(group, sequence);

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
