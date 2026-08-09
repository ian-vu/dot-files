/**
 * Generic slash-command-to-shell-command bridge.
 *
 * Reads `~/.pi/agent/shell-commands.json` and registers one Pi slash command per
 * entry, so new shortcuts can be added as JSON without editing this file. Each
 * entry is keyed by a short name and has:
 *
 *   command     string | string[]  Shell argv to run. A string is split on
 *                                 whitespace; an array is used verbatim.
 *   description string?           Shown in `/` autocomplete.
 *   args        "append"|"ignore"  How slash-command args are handled. "append"
 *                                 (default) appends them to argv, so
 *                                 `/command:pr-open 123` runs `gh pr view --web 123`.
 *                                 "ignore" drops them.
 *
 * Every command is registered under a `command:` prefix (e.g. an entry named
 * `pr-open` becomes `/command:pr-open`), mirroring the `skill:` convention so all
 * shell-shortcut commands group together in `/` autocomplete.
 *
 * Commands run detached with stdio ignored so a slow launch or browser window
 * never blocks the Pi UI. The config is re-read on each invocation, so command
 * argv can be edited live; only command *names* are fixed at Pi startup (they
 * drive autocomplete registration).
 */

import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Prefix mirroring Pi's `skill:` convention so all shortcuts group in `/`.
const COMMAND_PREFIX = "command:";
const CONFIG_PATH = join(homedir(), ".pi", "agent", "shell-commands.json");

type Entry = {
	command?: string | string[];
	description?: string;
	args?: "append" | "ignore";
};

type Config = Record<string, Entry>;

export default function (pi: ExtensionAPI) {
	const entries = Object.entries(readConfig());

	for (const [name, entry] of entries) {
		pi.registerCommand(`${COMMAND_PREFIX}${name}`, {
			description: entry.description ?? `Run ${argvSummary(entry)}`,
			handler: async (args, ctx) => {
				// Re-read so argv edits apply without restarting Pi.
				const current = readConfig()[name];
				if (!current) {
					ctx.ui.notify(
						`/${COMMAND_PREFIX}${name} was removed from shell-commands.json; restart Pi.`,
						"warning",
					);
					return;
				}

				const argv = buildArgv(current);
				if (argv.length === 0) {
					ctx.ui.notify(
						`/${COMMAND_PREFIX}${name} has no command configured`,
						"warning",
					);
					return;
				}

				if ((current.args ?? "append") === "append") {
					for (const arg of splitArgs(args)) argv.push(arg);
				}

				const child = spawn(argv[0], argv.slice(1), {
					detached: true,
					stdio: "ignore",
				});
				child.unref();

				ctx.ui.notify(`Running: ${argv.join(" ")}`, "info");
			},
		});
	}
}

function readConfig(): Config {
	try {
		const parsed = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
		if (parsed && typeof parsed === "object") return parsed as Config;
	} catch (error) {
			// Missing or malformed config is non-fatal; Pi just has no commands.
		}
		return {};
}

function buildArgv(entry: Entry): string[] {
	const command = entry.command;
	if (Array.isArray(command)) return [...command];
	if (typeof command === "string") return splitArgs(command);
	return [];
}

function splitArgs(value: string): string[] {
	// Minimal whitespace tokenizer; entries needing quotes should use the array
	// form so they don't depend on shell parsing here.
	return value.trim().split(/\s+/).filter(Boolean);
}

function argvSummary(entry: Entry): string {
	const argv = buildArgv(entry);
	return argv.length > 0 ? argv.join(" ") : "(unset)";
}
