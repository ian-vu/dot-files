export type SegmentName = "model" | "thinking" | "context" | "cost" | "progress" | "extensions";

export const DEFAULT_SEGMENTS: SegmentName[] = [
	"model",
	"thinking",
	"context",
	"cost",
	"progress",
	"extensions",
];
export const ALL_SEGMENTS: readonly SegmentName[] = [
	"model",
	"thinking",
	"context",
	"cost",
	"progress",
	"extensions",
];
export const SEGMENT_LABELS: Record<SegmentName, string> = {
	model: "Model",
	thinking: "Thinking level",
	context: "Context usage",
	cost: "Session cost",
	progress: "Progress update",
	extensions: "Extension statuses",
};
export const SEGMENT_SEPARATOR = "❯";
export const EXTENSION_STATUS_SEPARATOR = SEGMENT_SEPARATOR;

export function isSegmentName(value: string): value is SegmentName {
	return (ALL_SEGMENTS as readonly string[]).includes(value);
}

export function parseSegments(): SegmentName[] {
	const raw = process.env.STATUS_BAR_SHOW ?? process.env.PI_BAR_SHOW;
	if (!raw) return DEFAULT_SEGMENTS;

	const requested = raw
		.split(",")
		.map((segment) => segment.trim().toLowerCase())
		.filter(isSegmentName);

	return requested.length > 0 ? requested : DEFAULT_SEGMENTS;
}

export function serializeSegments(segments: readonly SegmentName[]): SegmentName[] {
	return ALL_SEGMENTS.filter((segment) => segments.includes(segment));
}

export function parseSerializedSegments(value: unknown): SegmentName[] | null {
	if (!Array.isArray(value)) return null;
	const segments = value.filter(
		(segment): segment is SegmentName => typeof segment === "string" && isSegmentName(segment),
	);
	return serializeSegments(segments);
}

export function splitSegmentNames(raw: string): SegmentName[] {
	return raw
		.split(/[\s,]+/)
		.map((segment) => segment.trim().toLowerCase())
		.filter(isSegmentName);
}

export function describeSegments(segments: readonly SegmentName[]): string {
	if (segments.length === 0) return "showing none";
	return `showing: ${segments.map((segment) => SEGMENT_LABELS[segment]).join(", ")}`;
}
