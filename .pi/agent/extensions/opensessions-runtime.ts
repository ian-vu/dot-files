/**
 * Derived from the official opensessions Pi extension:
 * https://github.com/Ataraxy-Labs/opensessions/blob/main/integrations/pi-extension/opensessions-runtime.ts
 *
 * To update: fetch the upstream file, diff it against this file, port relevant
 * changes, then keep these local compatibility patches: import types from
 * `@earendil-works/pi-coding-agent`, use `ctx.cwd` for the current directory,
 * preserve session id/name fallbacks, and leave the heartbeat `unref()` call.
 * Verify with: `(cd .pi/agent/extensions && npx tsc --project tsconfig.json)`.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface PiRuntimePayload {
	pid: number;
	ppid: number;
	sessionId: string;
	sessionFile?: string;
	cwd: string;
	sessionName?: string;
	ts: number;
}

type AgentStatus = "running" | "done" | "error" | "interrupted";

interface AgentEventPayload {
	agent: "pi";
	status: AgentStatus;
	threadId: string;
	threadName?: string;
	lastUserPrompt?: string;
	projectDir: string;
	paneId?: string;
	ts: number;
}

const DEFAULT_SERVER_PORT = 7391;
const RUST_SERVER_PORT_BASE = 22000;
const HEARTBEAT_MS = 5_000;

/**
 * Register this Pi process with opensessions so the sidebar can map live Pi
 * sessions to exact tmux panes. Network failures are ignored because the tmux
 * plugin starts the opensessions server lazily when the sidebar is opened.
 */
export default function opensessionsRuntime(pi: ExtensionAPI) {
	let heartbeat: ReturnType<typeof setInterval> | null = null;
	let current: Omit<PiRuntimePayload, "ts" | "sessionName"> | null = null;

	function buildPayload(ctx: ExtensionContext): PiRuntimePayload {
		return {
			pid: process.pid,
			ppid: process.ppid,
			sessionId: resolveSessionId(ctx),
			sessionFile: ctx.sessionManager.getSessionFile(),
			cwd: ctx.cwd,
			sessionName: resolveSessionName(pi, ctx),
			ts: Date.now(),
		};
	}

	async function post(path: string, body: unknown): Promise<void> {
		for (const serverUrl of resolveServerUrls()) {
			try {
				const response = await fetch(`${serverUrl}${path}`, {
					method: "POST",
					headers: { "content-type": "application/json" },
					body: JSON.stringify(body),
				});
				if (response.status >= 200 && response.status < 300) return;
			} catch {
				// Retry on the next event or heartbeat; opensessions may not be running.
			}
		}
	}

	function agentPayload(
		status: AgentStatus,
		ctx: ExtensionContext,
		lastUserPrompt?: string,
	): AgentEventPayload {
		return {
			agent: "pi",
			status,
			threadId: resolveSessionId(ctx),
			threadName: resolveSessionName(pi, ctx),
			lastUserPrompt,
			projectDir: ctx.cwd,
			paneId: resolveTmuxPaneId(),
			ts: Date.now(),
		};
	}

	function clearHeartbeat(): void {
		if (!heartbeat) return;
		clearInterval(heartbeat);
		heartbeat = null;
	}

	function startHeartbeat(ctx: ExtensionContext): void {
		clearHeartbeat();
		heartbeat = setInterval(() => {
			if (!current) {
				current = {
					pid: process.pid,
					ppid: process.ppid,
					sessionId: resolveSessionId(ctx),
					sessionFile: ctx.sessionManager.getSessionFile(),
					cwd: ctx.cwd,
				};
			}
			void post("/api/runtime/pi/upsert", {
				...current,
				sessionName: resolveSessionName(pi, ctx),
				ts: Date.now(),
			} satisfies PiRuntimePayload);
		}, HEARTBEAT_MS);
		heartbeat.unref?.();
	}

	pi.on("session_start", async (_event, ctx) => {
		const payload = buildPayload(ctx);
		current = {
			pid: payload.pid,
			ppid: payload.ppid,
			sessionId: payload.sessionId,
			sessionFile: payload.sessionFile,
			cwd: payload.cwd,
		};
		void post("/api/runtime/pi/upsert", payload);
		startHeartbeat(ctx);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		void post(
			"/api/agent-event",
			agentPayload("running", ctx, typeof event.prompt === "string" ? event.prompt : undefined),
		);
	});

	pi.on("agent_end", async (_event, ctx) => {
		void post("/api/agent-event", agentPayload("done", ctx));
	});

	pi.on("session_shutdown", async () => {
		clearHeartbeat();
		current = null;
		void post("/api/runtime/pi/delete", { pid: process.pid });
	});
}

/**
 * Mirror opensessions Rust runtime port resolution: derive a stable server port
 * from the tmux socket so multiple tmux servers do not fight over one endpoint.
 */
function hashServerKey(input: string): number {
	let hash = 0;
	for (let i = 0; i < input.length; i += 1) {
		hash = (hash + input.charCodeAt(i) * (i + 1)) % 20000;
	}
	return hash;
}

function resolveServerUrls(): string[] {
	const urls: string[] = [];
	const add = (url: string | undefined): void => {
		if (url && !urls.includes(url)) urls.push(url);
	};

	add(process.env.OPENSESSIONS_URL?.replace(/\/+$/, ""));

	const explicit = Number.parseInt(process.env.OPENSESSIONS_PORT ?? "", 10);
	if (Number.isFinite(explicit) && explicit > 0) add(`http://127.0.0.1:${explicit}`);

	const explicitKey = process.env.OPENSESSIONS_SERVER_KEY?.trim();
	if (explicitKey) {
		const key = Number.parseInt(explicitKey, 10);
		if (Number.isFinite(key)) add(`http://127.0.0.1:${RUST_SERVER_PORT_BASE + key}`);
	}

	const tmux = process.env.TMUX?.trim();
	if (tmux) {
		const socketPath = tmux.split(",", 1)[0];
		if (socketPath) add(`http://127.0.0.1:${RUST_SERVER_PORT_BASE + hashServerKey(socketPath)}`);
	}

	add(`http://127.0.0.1:${DEFAULT_SERVER_PORT}`);
	return urls;
}

function resolveSessionId(ctx: ExtensionContext): string {
	return ctx.sessionManager.getSessionId() ?? ctx.sessionManager.getSessionFile() ?? `pid:${process.pid}`;
}

function resolveSessionName(pi: ExtensionAPI, ctx: ExtensionContext): string | undefined {
	return pi.getSessionName() ?? ctx.sessionManager.getSessionName() ?? undefined;
}

function resolveTmuxPaneId(): string | undefined {
	// opensessions uses paneId from agent events to route agent-row clicks to the
	// exact tmux pane running Pi; TMUX_PANE is stable even if the pane moves.
	return process.env.TMUX_PANE?.trim() || undefined;
}
