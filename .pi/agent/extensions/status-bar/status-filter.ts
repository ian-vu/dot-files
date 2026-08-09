import { stripTerminalControls } from "./progress/engine.js";

export type StatusFilter =
  | { mode: "all"; hidden: Set<string> }
  | { mode: "only"; shown: Set<string> };
export type SerializedStatusFilter =
  | { mode: "all"; hidden: string[] }
  | { mode: "only"; shown: string[] };
export type FormattedExtensionStatus = { key: string; text: string };

function formatMcpStatus(text: string): string | null | undefined {
  // The adapter's detailed status reports connected servers after the enabled
  // count. Keep both counts while dropping its icon and explanatory wording.
  const detailedMatch = text.match(
    /^(?:🔌\s*)?MCP:\s*(\d+)\s+servers?\s+enabled(?:\s+\((\d+)\s+connected\))?(?:\s+\(\d+\s+disabled\))?$/i,
  );
  if (detailedMatch) {
    const enabledServers = Number(detailedMatch[1]);
    const connectedServers = Number(detailedMatch[2] ?? 0);
    return enabledServers > 0 ? `mcp ${connectedServers}/${enabledServers}` : null;
  }

  const compactMatch = text.match(
    /^(?:MCP:\s*)?(\d+)(?:\/\d+)?(?:\s+servers?)?$/i,
  );
  if (!compactMatch) return undefined;

  const activeServers = Number(compactMatch[1]);
  return activeServers > 0 ? `mcp ${activeServers}` : null;
}

export function shouldShowStatus(key: string, filter: StatusFilter): boolean {
  if (filter.mode === "only") return filter.shown.has(key);
  return !filter.hidden.has(key);
}

export function formatExtensionStatuses(
  statuses: ReadonlyMap<string, string>,
  filter: StatusFilter,
  seenStatusKeys: Set<string>,
  mcpUsed: boolean,
): FormattedExtensionStatus[] | null {
  const parts = Array.from(statuses.entries())
    .map(
      ([key, text]) =>
        [
          stripTerminalControls(key),
          stripTerminalControls(text).trim(),
        ] as const,
    )
    .filter(([, text]) => text.length > 0)
    .filter(([key]) => {
      seenStatusKeys.add(key);
      return shouldShowStatus(key, filter);
    })
    .flatMap(([key, text]): FormattedExtensionStatus[] => {
      // The MCP adapter reports enabled servers continuously. Show its status only
      // after this session has called an MCP tool.
      if (key === "mcp" && !mcpUsed) return [];
      const mcpText = key === "mcp" ? formatMcpStatus(text) : undefined;
      if (mcpText === null) return [];
      return [{ key, text: mcpText ?? `${key}:${text}` }];
    });

  return parts.length > 0 ? parts : null;
}

export function serializeStatusFilter(
  filter: StatusFilter,
): SerializedStatusFilter {
  if (filter.mode === "only") {
    return { mode: "only", shown: Array.from(filter.shown).sort() };
  }
  return { mode: "all", hidden: Array.from(filter.hidden).sort() };
}

export function parseSerializedStatusFilter(
  value: unknown,
): StatusFilter | null {
  if (!value || typeof value !== "object") return null;
  const data = value as Partial<SerializedStatusFilter>;

  if (data.mode === "only" && Array.isArray(data.shown)) {
    return { mode: "only", shown: new Set(data.shown) };
  }
  if (data.mode === "all" && Array.isArray(data.hidden)) {
    return { mode: "all", hidden: new Set(data.hidden) };
  }
  return null;
}

export function splitStatusKeys(raw: string): string[] {
  return raw
    .split(/[\s,]+/)
    .map((key) => key.trim())
    .filter(Boolean);
}

export function describeStatusFilter(filter: StatusFilter): string {
  if (filter.mode === "only") {
    const shown = Array.from(filter.shown).sort();
    return shown.length > 0
      ? `showing only: ${shown.join(", ")}`
      : "showing none";
  }

  const hidden = Array.from(filter.hidden).sort();
  return hidden.length > 0
    ? `showing all except: ${hidden.join(", ")}`
    : "showing all";
}

export function getKnownStatusKeys(
  filter: StatusFilter,
  seenStatusKeys: Set<string>,
): string[] {
  const keys = new Set(seenStatusKeys);
  if (filter.mode === "only") {
    for (const key of filter.shown) keys.add(key);
  } else {
    for (const key of filter.hidden) keys.add(key);
  }
  return Array.from(keys).sort();
}
