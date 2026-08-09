/**
 * Append per-repo, user-private context after normal AGENTS.md context.
 *
 * This lets each checkout keep machine-specific notes such as required local
 * environment flags without committing them to the shared repository context.
 */

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOCAL_CONTEXT_RELATIVE_PATH = join(".pi", "LOCAL_CONTEXT.md");

type LocalContextFile = {
	path: string;
	content: string;
};


function gitRoot(cwd: string): string | undefined {
	try {
		const output = execFileSync("git", ["-C", cwd, "rev-parse", "--show-toplevel"], {
			encoding: "utf8",
			stdio: ["ignore", "pipe", "ignore"],
		}).trim();
		return output ? resolve(output) : undefined;
	} catch {
		return undefined;
	}
}

function isUnderPath(path: string, root: string): boolean {
	const normalizedPath = resolve(path);
	const normalizedRoot = resolve(root);
	return normalizedPath === normalizedRoot || normalizedPath.startsWith(`${normalizedRoot}${sep}`);
}

function directoriesFromRootToCwd(root: string, cwd: string): string[] {
	const normalizedRoot = resolve(root);
	const normalizedCwd = resolve(cwd);
	if (!isUnderPath(normalizedCwd, normalizedRoot)) return [normalizedCwd];

	const dirs = [normalizedRoot];
	let current = normalizedRoot;
	for (const segment of relative(normalizedRoot, normalizedCwd).split(sep).filter(Boolean)) {
		current = join(current, segment);
		dirs.push(current);
	}
	return dirs;
}

function fallbackDirectories(cwd: string): string[] {
	const home = resolve(homedir());
	const dirs: string[] = [];
	let current = resolve(cwd);

	while (true) {
		dirs.unshift(current);
		if (current === home || current === dirname(current)) break;
		current = dirname(current);
	}
	return dirs;
}

function discoverLocalContextFiles(cwd: string): LocalContextFile[] {
	const root = gitRoot(cwd);
	const dirs = root ? directoriesFromRootToCwd(root, cwd) : fallbackDirectories(cwd);
	const seen = new Set<string>();
	const files: LocalContextFile[] = [];

	for (const dir of dirs) {
		const path = resolve(dir, LOCAL_CONTEXT_RELATIVE_PATH);
		if (seen.has(path) || !existsSync(path)) continue;
		seen.add(path);

		try {
			const content = readFileSync(path, "utf8").trim();
			if (content.length > 0) files.push({ path, content });
		} catch {
			// Ignore unreadable private context files so Pi startup/turns are not broken
			// by transient permissions or editor swap-file states.
		}
	}

	return files;
}

function formatLocalContext(files: LocalContextFile[]): string {
	const sections = files
		.map(({ path, content }) => `## ${path}\n\n${content}`)
		.join("\n\n");

	return `# User-private local context

These context notes are local to this checkout/user and intentionally separate from shared AGENTS.md files. Use them for local environment assumptions, command invocation details, and workflow context for this machine.

${sections}`;
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const files = discoverLocalContextFiles(ctx.cwd);
		if (files.length === 0) return;

		return {
			systemPrompt: `${event.systemPrompt}\n\n${formatLocalContext(files)}`,
		};
	});
}
