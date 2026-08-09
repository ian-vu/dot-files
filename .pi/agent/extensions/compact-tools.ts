/**
 * Make collapsed tool calls consume minimal screen space.
 *
 * Pi's default collapsed renderers can show sizeable output previews; this keeps
 * selected tools compact while still allowing full output via /expand or Ctrl+O.
 * Per-tool settings live next to this extension so future options can be added
 * without changing the config shape.
 */

import { readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, sep } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashTool, createReadTool, keyHint } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const CONFIG_PATH = join(dirname(fileURLToPath(import.meta.url)), "..", "compact-tools.json");
const DEFAULT_COMPACT_LINES = 8;

const readToolCache = new Map<string, ReturnType<typeof createReadTool>>();
const bashToolCache = new Map<string, ReturnType<typeof createBashTool>>();

let cachedConfig: CompactToolsConfig | undefined;
let cachedConfigMtimeMs: number | undefined;

type ToolCompactConfig = {
	enabled?: boolean;
	compact_lines?: number;
	show_muted_text?: boolean;
	[key: string]: unknown;
};

type CompactToolsConfig = {
	tools?: Record<string, ToolCompactConfig>;
};

type ResolvedToolCompactConfig = Required<Pick<ToolCompactConfig, "enabled" | "compact_lines" | "show_muted_text">> &
	ToolCompactConfig;

type TextToolResult = {
	content?: Array<{ type: string; text?: string }>;
};

type BuiltInRenderers = {
	renderCall?: (args: unknown, theme: unknown, context: unknown) => Text;
	renderResult?: (result: unknown, options: unknown, theme: unknown, context: unknown) => Text;
};

const defaultConfig = {
	tools: {
		read: { enabled: true, compact_lines: 0, show_muted_text: true },
		bash: { enabled: true, compact_lines: DEFAULT_COMPACT_LINES, show_muted_text: true },
	},
} satisfies Required<CompactToolsConfig>;

function withRenderers<T>(tool: T): T & BuiltInRenderers {
	return tool as T & BuiltInRenderers;
}

function isMissingFileError(error: unknown): boolean {
	return typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT";
}

function readConfig(): CompactToolsConfig {
	try {
		const { mtimeMs } = statSync(CONFIG_PATH);
		// renderCall/renderResult run often; mtime caching avoids reparsing JSON on every TUI render.
		if (cachedConfig && cachedConfigMtimeMs === mtimeMs) return cachedConfig;

		cachedConfig = JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as CompactToolsConfig;
		cachedConfigMtimeMs = mtimeMs;
		return cachedConfig;
	} catch (error) {
		if (!isMissingFileError(error)) {
			console.warn(`[compact-tools] Failed to read ${CONFIG_PATH}:`, error);
		}
		return defaultConfig;
	}
}

function getToolConfig(toolName: string, config = readConfig()): ResolvedToolCompactConfig {
	const toolDefaults = defaultConfig.tools[toolName as keyof typeof defaultConfig.tools] ?? {
		enabled: true,
		compact_lines: DEFAULT_COMPACT_LINES,
		show_muted_text: true,
	};
	const toolConfig = { ...toolDefaults, ...(config.tools?.[toolName] ?? {}) };

	return {
		...toolConfig,
		enabled: toolConfig.enabled ?? true,
		compact_lines: toolConfig.compact_lines ?? DEFAULT_COMPACT_LINES,
		show_muted_text: toolConfig.show_muted_text ?? true,
	};
}

function compactLineCount(config: ResolvedToolCompactConfig): number {
	return Number.isFinite(config.compact_lines) && config.compact_lines > 0 ? Math.floor(config.compact_lines) : 0;
}

function getReadTool(cwd: string) {
	let tool = readToolCache.get(cwd);
	if (!tool) {
		tool = createReadTool(cwd);
		readToolCache.set(cwd, tool);
	}
	return tool;
}

function getBashTool(cwd: string) {
	let tool = bashToolCache.get(cwd);
	if (!tool) {
		tool = createBashTool(cwd);
		bashToolCache.set(cwd, tool);
	}
	return tool;
}

function shortenPath(path: string): string {
	const home = homedir();
	return path === home || path.startsWith(`${home}${sep}`) ? `~${path.slice(home.length)}` : path;
}

function collapsedHint(theme: any, config: ResolvedToolCompactConfig): Text {
	// Some users prefer fully silent collapsed results; keep the hint flag per tool.
	if (!config.show_muted_text) return new Text("", 0, 0);

	return new Text(
		`${theme.fg("muted", "\n... (")}${keyHint("app.tools.expand", "for full output")}${theme.fg(
			"muted",
			", /expand for default preview)",
		)}`,
		0,
		0,
	);
}

function splitPreviewLines(text: string, maxLines: number): { previewLines: string[]; totalLines: number } {
	const previewLines: string[] = [];
	let totalLines = 1;
	let lineStart = 0;

	// Avoid allocating every output line when collapsed mode only displays the first few.
	for (let index = 0; index < text.length; index++) {
		if (text.charCodeAt(index) !== 10) continue;
		if (previewLines.length < maxLines) previewLines.push(text.slice(lineStart, index));
		totalLines++;
		lineStart = index + 1;
	}

	if (previewLines.length < maxLines) previewLines.push(text.slice(lineStart));
	return { previewLines, totalLines };
}

function renderCompactResult(
	result: TextToolResult,
	options: { expanded?: boolean },
	theme: any,
	context: { expanded?: boolean } | unknown,
	baseTool: BuiltInRenderers,
	config: ResolvedToolCompactConfig,
): Text {
	const expanded = options.expanded || (typeof context === "object" && context !== null && "expanded" in context && context.expanded === true);
	if (!config.enabled && baseTool.renderResult) {
		return baseTool.renderResult(result, options, theme, context);
	}

	if (expanded) {
		// While tools are still running, the built-in renderer can continue showing
		// its own preview. Render raw text ourselves so Ctrl+O always reveals output.
		return fullOutput(result, theme) ?? (baseTool.renderResult ? baseTool.renderResult(result, options, theme, context) : compactOutput(result, config, theme));
	}

	return compactOutput(result, config, theme);
}

function fullOutput(result: TextToolResult, theme: any): Text | undefined {
	const textContent = result.content?.find((content) => content.type === "text");
	return textContent?.text ? new Text(`\n${theme.fg("toolOutput", textContent.text)}`, 0, 0) : undefined;
}

function compactOutput(result: TextToolResult, config: ResolvedToolCompactConfig, theme: any): Text {
	const lineCount = compactLineCount(config);
	if (lineCount === 0) return collapsedHint(theme, config);

	const textContent = result.content?.find((content) => content.type === "text");
	if (!textContent?.text) return collapsedHint(theme, config);

	const { previewLines, totalLines } = splitPreviewLines(textContent.text, lineCount);
	const preview = previewLines.map((line) => theme.fg("toolOutput", line)).join("\n");
	const hiddenLines = totalLines - previewLines.length;
	// keyHint includes its own styling reset, so mute the surrounding hint text in separate spans.
	const hint =
		config.show_muted_text && hiddenLines > 0
			? `${theme.fg("muted", `\n... (${hiddenLines} more lines; `)}${keyHint(
				"app.tools.expand",
				"for full output",
			)}${theme.fg("muted", " or /expand)")}`
			: "";
	return new Text(`\n${preview}${hint}`, 0, 0);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "read",
		label: "read",
		description:
			"Read the contents of a file. Supports text files and images (jpg, png, gif, webp). Images are sent as attachments. For text files, output is truncated to 2000 lines or 50KB (whichever is hit first). Use offset/limit for large files.",
		parameters: getReadTool(process.cwd()).parameters,

		async execute(toolCallId, params, signal, onUpdate, ctx) {
			return getReadTool(ctx.cwd).execute(toolCallId, params, signal, onUpdate);
		},

		renderCall(args, theme, context) {
			const baseReadTool = withRenderers(getReadTool(context.cwd));
			const config = getToolConfig("read");
			if (!config.enabled && baseReadTool.renderCall) {
				return baseReadTool.renderCall(args, theme, context);
			}

			let pathDisplay = args.path ? theme.fg("accent", shortenPath(args.path)) : theme.fg("toolOutput", "...");
			if (args.offset !== undefined || args.limit !== undefined) {
				const startLine = args.offset ?? 1;
				const endLine = args.limit !== undefined ? startLine + args.limit - 1 : "";
				pathDisplay += theme.fg("warning", `:${startLine}${endLine ? `-${endLine}` : ""}`);
			}
			return new Text(`${theme.fg("toolTitle", theme.bold("read"))} ${pathDisplay}`, 0, 0);
		},

		renderResult(result, options, theme, context) {
			const baseReadTool = withRenderers(getReadTool(context.cwd));
			const config = getToolConfig("read");
			return renderCompactResult(result, options, theme, context, baseReadTool, config);
		},
	});

	pi.registerTool({
		name: "bash",
		label: "bash",
		description:
			"Execute a bash command in the current working directory. Returns stdout and stderr. Output is truncated to last 2000 lines or 50KB (whichever is hit first). If truncated, full output is saved to a temp file. Optionally provide a timeout in seconds.",
		parameters: getBashTool(process.cwd()).parameters,

		async execute(toolCallId, params, signal, onUpdate, ctx) {
			return getBashTool(ctx.cwd).execute(toolCallId, params, signal, onUpdate);
		},

		renderCall(args, theme, context) {
			const baseBashTool = withRenderers(getBashTool(context.cwd));
			const config = getToolConfig("bash");
			if (!config.enabled && baseBashTool.renderCall) {
				return baseBashTool.renderCall(args, theme, context);
			}

			const command = args.command ? theme.fg("accent", args.command) : theme.fg("toolOutput", "...");
			const timeout = args.timeout !== undefined ? theme.fg("warning", ` timeout=${args.timeout}s`) : "";
			return new Text(`${theme.fg("toolTitle", theme.bold("bash"))} ${command}${timeout}`, 0, 0);
		},

		renderResult(result, options, theme, context) {
			const baseBashTool = withRenderers(getBashTool(context.cwd));
			const config = getToolConfig("bash");
			return renderCompactResult(result, options, theme, context, baseBashTool, config);
		},
	});
}
