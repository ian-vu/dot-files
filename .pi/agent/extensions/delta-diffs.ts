/**
 * Render edit/write results through delta so tool output focuses on changed hunks.
 *
 * Pi's write preview shows file contents while arguments stream; this override keeps the
 * call compact and renders a unified diff after execution, colorized by delta when present.
 */

import { Text } from "@earendil-works/pi-tui";
import { type ExtensionAPI, createEditTool, withFileMutationQueue } from "@earendil-works/pi-coding-agent";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { access } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { spawn } from "node:child_process";
import { Type } from "typebox";

const writeSchema = Type.Object({
	path: Type.String({ description: "Path to the file to write (relative or absolute)" }),
	content: Type.String({ description: "Content to write to the file" }),
});

type ToolResult = {
	content: Array<{ type: "text"; text: string }>;
	details?: Record<string, unknown>;
};

function shortenPath(path: string): string {
	return path.replace(process.env.HOME ?? "", "~");
}

function run(command: string, args: string[], input?: string): Promise<string> {
	return new Promise((resolvePromise, reject) => {
		const child = spawn(command, args, { stdio: [input === undefined ? "ignore" : "pipe", "pipe", "pipe"] });
		let stdout = "";
		let stderr = "";

		child.stdout.setEncoding("utf8");
		child.stderr.setEncoding("utf8");
		child.stdout.on("data", (chunk) => (stdout += chunk));
		child.stderr.on("data", (chunk) => (stderr += chunk));
		child.on("error", reject);
		child.on("close", (code) => {
			// diff exits 1 when files differ; that is success for our use case.
			if (code === 0 || (command === "diff" && code === 1)) resolvePromise(stdout);
			else reject(new Error(stderr || `${command} exited ${code}`));
		});

		if (input !== undefined && child.stdin) {
			child.stdin.end(input);
		}
	});
}

async function unifiedDiff(oldContent: string, newContent: string, path: string): Promise<string> {
	const dir = await mkdtemp(join(tmpdir(), "pi-delta-diff-"));
	try {
		const oldFile = join(dir, "old");
		const newFile = join(dir, "new");
		await writeFile(oldFile, oldContent, "utf8");
		await writeFile(newFile, newContent, "utf8");
		return await run("diff", ["-u", "--label", `a/${path}`, "--label", `b/${path}`, oldFile, newFile]);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
}

function sanitizeTerminalControls(text: string): string {
	// Pi renders this inside its own TUI. Keep SGR color codes, but drop cursor/erase
	// controls such as ESC[0K from delta because they can stall or corrupt tmux redraws.
	return text
		.replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
		.replace(/\x1b\[(?![0-9;]*m)[0-9;?]*[ -/]*[@-~]/g, "");
}

async function deltaize(diff: string): Promise<string> {
	// Feed delta the complete unified diff; removing file headers breaks some delta layouts.
	if (!diff.trim()) return "";
	try {
		return sanitizeTerminalControls(await run("delta", ["--color-only", "--paging=never"], diff));
	} catch {
		// Keep working on machines without delta installed.
		return diff;
	}
}

function renderHeader(name: string, path: unknown, theme: any): string {
	const pathText = typeof path === "string" && path ? theme.fg("accent", shortenPath(path)) : theme.fg("toolOutput", "...");
	return `${theme.fg("toolTitle", theme.bold(name))} ${pathText}`;
}

function renderDiffResult(name: string, result: ToolResult, theme: any, context: any): Text {
	if (context.isError) {
		const error = result.content.map((content) => content.text).join("\n");
		return new Text(error ? `\n${theme.fg("error", error)}` : "", 0, 0);
	}

	const diff = typeof result.details?.deltaDiff === "string" ? result.details.deltaDiff : "";
	if (!diff.trim()) return new Text("", 0, 0);
	return new Text(`\n${diff}`, 0, 0);
}

export default function (pi: ExtensionAPI) {
	const editTools = new Map<string, ReturnType<typeof createEditTool>>();
	const getEditTool = (cwd: string) => {
		let tool = editTools.get(cwd);
		if (!tool) {
			tool = createEditTool(cwd);
			editTools.set(cwd, tool);
		}
		return tool;
	};

	pi.registerTool({
		name: "edit",
		label: "edit",
		description: getEditTool(process.cwd()).description,
		parameters: getEditTool(process.cwd()).parameters,
		prepareArguments: getEditTool(process.cwd()).prepareArguments,

		async execute(toolCallId, params, signal, onUpdate, ctx) {
			const result = (await getEditTool(ctx.cwd).execute(toolCallId, params, signal, onUpdate)) as ToolResult;
			const diff = typeof result.details?.diff === "string" ? result.details.diff : "";
			return { ...result, details: { ...result.details, deltaDiff: await deltaize(diff) } };
		},

		renderCall(args, theme) {
			return new Text(renderHeader("edit", (args as { path?: unknown })?.path, theme), 0, 0);
		},

		renderResult(result, _options, theme, context) {
			return renderDiffResult("edit", result as ToolResult, theme, context);
		},
	});

	pi.registerTool({
		name: "write",
		label: "write",
		description:
			"Write content to a file. Creates the file if it doesn't exist, overwrites if it does. Automatically creates parent directories.",
		parameters: writeSchema,
		promptSnippet: "Create or overwrite files",
		promptGuidelines: ["Use write only for new files or complete rewrites."],

		async execute(_toolCallId, { path, content }, signal, _onUpdate, ctx) {
			const absolutePath = resolve(ctx.cwd, path);
			return withFileMutationQueue(absolutePath, async () => {
				if (signal?.aborted) throw new Error("Operation aborted");
				let oldContent = "";
				try {
					await access(absolutePath, constants.R_OK);
					oldContent = await readFile(absolutePath, "utf8");
				} catch {
					// Missing/unreadable files are rendered as creation from an empty file.
				}

				await mkdir(dirname(absolutePath), { recursive: true });
				if (signal?.aborted) throw new Error("Operation aborted");
				await writeFile(absolutePath, content, "utf8");

				const diff = await unifiedDiff(oldContent, content, path);
				return {
					content: [{ type: "text", text: `Successfully wrote ${content.length} bytes to ${path}` }],
					details: { diff, deltaDiff: await deltaize(diff) },
				};
			});
		},

		renderCall(args, theme) {
			return new Text(renderHeader("write", (args as { path?: unknown })?.path, theme), 0, 0);
		},

		renderResult(result, _options, theme, context) {
			return renderDiffResult("write", result as ToolResult, theme, context);
		},
	});
}
