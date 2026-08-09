import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ThemeColor } from "@earendil-works/pi-coding-agent";
import { parseSegments, parseSerializedSegments, serializeSegments, type SegmentName } from "./segments.js";
import { parseSerializedStatusFilter, serializeStatusFilter, type SerializedStatusFilter, type StatusFilter } from "./status-filter.js";

export type ThresholdStop = { threshold: number; color: ThemeColor };
type ThresholdConfig = Array<Partial<ThresholdStop>>;
type GlobalBarConfig = {
	statusFilter?: SerializedStatusFilter;
	segments?: SegmentName[];
	thresholds?: { context?: ThresholdConfig; contextPercent?: ThresholdConfig; cost?: ThresholdConfig };
};

const LEGACY_CONFIG_PATH = join(homedir(), ".pi", "agent", "pi-bar.json");
const CONFIG_PATH =
	process.env.STATUS_BAR_CONFIG ?? process.env.PI_BAR_CONFIG ?? join(homedir(), ".pi", "agent", "status-bar.json");

const THEME_COLORS = new Set<ThemeColor>([
	"accent", "border", "borderAccent", "borderMuted", "success", "error", "warning", "muted", "dim", "text",
	"thinkingText", "userMessageText", "customMessageText", "customMessageLabel", "toolTitle", "toolOutput",
	"mdHeading", "mdLink", "mdLinkUrl", "mdCode", "mdCodeBlock", "mdCodeBlockBorder", "mdQuote", "mdQuoteBorder",
	"mdHr", "mdListBullet", "toolDiffAdded", "toolDiffRemoved", "toolDiffContext", "syntaxComment", "syntaxKeyword",
	"syntaxFunction", "syntaxVariable", "syntaxString", "syntaxNumber", "syntaxType", "syntaxOperator", "syntaxPunctuation",
	"thinkingOff", "thinkingMinimal", "thinkingLow", "thinkingMedium", "thinkingHigh", "thinkingXhigh", "bashMode",
]);

// Context thresholds are absolute token counts consumed in the context window,
// not percentages, so the color reflects real usage independent of window size.
const DEFAULT_CONTEXT_THRESHOLDS: ThresholdStop[] = [
	{ threshold: 0, color: "success" },
	{ threshold: 120_000, color: "warning" },
	{ threshold: 160_000, color: "syntaxVariable" },
	{ threshold: 184_000, color: "error" },
];
// Percent thresholds color the trailing "12.3%" independently of the
// token-count color, expressed as percent of the context window used.
const DEFAULT_CONTEXT_PERCENT_THRESHOLDS: ThresholdStop[] = [
	{ threshold: 0, color: "success" },
	{ threshold: 60, color: "warning" },
	{ threshold: 80, color: "syntaxVariable" },
	{ threshold: 92, color: "error" },
];
const DEFAULT_COST_THRESHOLDS: ThresholdStop[] = [
	{ threshold: 0, color: "syntaxFunction" },
	{ threshold: 0.5, color: "warning" },
	{ threshold: 1, color: "syntaxVariable" },
	{ threshold: 3, color: "error" },
];

function isThemeColor(value: string): value is ThemeColor {
	return THEME_COLORS.has(value as ThemeColor);
}

function sanitizeThresholds(value: unknown, fallback: readonly ThresholdStop[]): ThresholdStop[] {
	if (!Array.isArray(value)) return [...fallback];
	const stops = value.flatMap((entry): ThresholdStop[] => {
		if (!entry || typeof entry !== "object") return [];
		const { threshold, color } = entry as Record<string, unknown>;
		if (typeof threshold !== "number" || !Number.isFinite(threshold) || threshold < 0) return [];
		if (typeof color !== "string" || !isThemeColor(color)) return [];
		return [{ threshold, color }];
	});
	if (stops.length === 0) return [...fallback];
	return stops.sort((a, b) => a.threshold - b.threshold);
}

function parseThresholdEnv(value: string | undefined): ThresholdConfig | undefined {
	if (!value) return undefined;
	const stops = value.split(",").flatMap((part): ThresholdConfig => {
		const [color, rawThreshold] = part.split(":").map((piece) => piece.trim());
		const threshold = Number.parseFloat(rawThreshold ?? "");
		return Number.isFinite(threshold) && color ? [{ color: color as ThemeColor, threshold }] : [];
	});
	return stops.length > 0 ? stops : undefined;
}

function legacyContextThresholds(): ThresholdConfig | undefined {
	const raw = process.env.STATUS_BAR_THRESHOLDS ?? process.env.PI_BAR_THRESHOLDS;
	if (!raw) return undefined;
	const [warning, error] = raw.split(",").map((value) => Number.parseFloat(value.trim()));
	if (!Number.isFinite(warning) || !Number.isFinite(error) || warning < 0 || error <= warning) return undefined;
	return [
		{ threshold: 0, color: "success" },
		{ threshold: warning, color: "warning" },
		{ threshold: error, color: "error" },
	];
}

export function readColorThresholds(): { context: ThresholdStop[]; contextPercent: ThresholdStop[]; cost: ThresholdStop[] } {
	const config = readGlobalConfig().thresholds;
	return {
		context: sanitizeThresholds(
			parseThresholdEnv(process.env.STATUS_BAR_CONTEXT_THRESHOLDS ?? process.env.PI_BAR_CONTEXT_THRESHOLDS) ?? legacyContextThresholds() ?? config?.context,
			DEFAULT_CONTEXT_THRESHOLDS,
		),
		contextPercent: sanitizeThresholds(
			parseThresholdEnv(process.env.STATUS_BAR_CONTEXT_PERCENT_THRESHOLDS) ?? config?.contextPercent,
			DEFAULT_CONTEXT_PERCENT_THRESHOLDS,
		),
		cost: sanitizeThresholds(
			parseThresholdEnv(process.env.STATUS_BAR_COST_THRESHOLDS ?? process.env.PI_BAR_COST_THRESHOLDS) ?? config?.cost,
			DEFAULT_COST_THRESHOLDS,
		),
	};
}

function readConfigFile(path: string): GlobalBarConfig | null {
	try {
		const data = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		const statusFilter = parseSerializedStatusFilter(data.statusFilter ?? data);
		const thresholds = data.thresholds && typeof data.thresholds === "object" && !Array.isArray(data.thresholds)
			? data.thresholds as GlobalBarConfig["thresholds"]
			: undefined;
		return {
			statusFilter: statusFilter ? serializeStatusFilter(statusFilter) : undefined,
			segments: parseSerializedSegments(data.segments) ?? undefined,
			thresholds,
		};
	} catch {
		return null;
	}
}

export function readGlobalConfig(): GlobalBarConfig {
	// Read old pi-bar.json only as migration fallback; writes go to status-bar.json.
	return readConfigFile(CONFIG_PATH) ?? readConfigFile(LEGACY_CONFIG_PATH) ?? {};
}

export function readGlobalStatusFilter(): StatusFilter | null {
	return parseSerializedStatusFilter(readGlobalConfig().statusFilter);
}

export function readGlobalSegments(): SegmentName[] | null {
	return (process.env.STATUS_BAR_SHOW ?? process.env.PI_BAR_SHOW) ? parseSegments() : readGlobalConfig().segments ?? null;
}

export function writeGlobalConfig(config: GlobalBarConfig): void {
	const data = JSON.stringify(config, null, 2);
	mkdirSync(dirname(CONFIG_PATH), { recursive: true });
	const tmpPath = `${CONFIG_PATH}.${process.pid}.tmp`;
	writeFileSync(tmpPath, `${data}\n`, "utf8");
	renameSync(tmpPath, CONFIG_PATH);
}

export function writeGlobalStatusFilter(filter: StatusFilter): void {
	const existing = readGlobalConfig();
	writeGlobalConfig({ ...existing, statusFilter: serializeStatusFilter(filter) });
}

export function writeGlobalSegments(segments: readonly SegmentName[]): void {
	const existing = readGlobalConfig();
	writeGlobalConfig({ ...existing, segments: serializeSegments(segments) });
}
