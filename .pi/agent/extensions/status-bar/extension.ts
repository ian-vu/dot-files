/**
 * Registers the status-bar extension and wires Pi events to focused modules.
 */

import {
  getSettingsListTheme,
  type ExtensionAPI,
  type ExtensionContext,
  type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import {
  Container,
  type SettingItem,
  SettingsList,
  truncateToWidth,
} from "@earendil-works/pi-tui";
import { CostTracker } from "./costs/session-cost.js";
import { DailyCostTracker, formatWholeCost } from "./costs/daily-cost.js";
import {
  readColorThresholds,
  readGlobalSegments,
  readGlobalStatusFilter,
  writeGlobalSegments,
  writeGlobalStatusFilter,
} from "./config.js";
import { FooterProgressEngine } from "./progress/engine.js";
import {
  ALL_SEGMENTS,
  DEFAULT_SEGMENTS,
  EXTENSION_STATUS_SEPARATOR,
  SEGMENT_LABELS,
  SEGMENT_SEPARATOR,
  describeSegments,
  isSegmentName,
  serializeSegments,
  splitSegmentNames,
  type SegmentName,
} from "./segments.js";
import {
  describeStatusFilter,
  formatExtensionStatuses,
  getKnownStatusKeys,
  parseSerializedStatusFilter,
  shouldShowStatus,
  splitStatusKeys,
  type StatusFilter,
} from "./status-filter.js";

const STATUS_FILTER_ENTRY_TYPE = "status-bar-status-filter";
const LEGACY_STATUS_FILTER_ENTRY_TYPE = "pi-bar-status-filter";

function formatTokens(n: number): string {
  if (n >= 1_000_000) {
    const value = n / 1_000_000;
    return value >= 10 ? `${Math.round(value)}M` : `${value.toFixed(1)}M`;
  }
  if (n >= 1_000) {
    const value = n / 1_000;
    return value >= 10 ? `${Math.round(value)}K` : `${value.toFixed(1)}K`;
  }
  return String(n);
}

function formatContextTokenRatio(
  tokens: number | null,
  contextWindow: number,
): string {
  const usedText = tokens === null ? "—" : formatTokens(tokens);
  return `${usedText}/${formatTokens(contextWindow)}`;
}

function formatModelName(id: string | undefined): string {
  if (!id) return "model";
  return id.replace(/^claude-/, "").replace(/-20\d{6}$/, "");
}

function thinkingColor(level: string): ThemeColor {
  // Keep Pi's thinking* theme tokens reserved for the editor borders. The
  // footer uses these existing palette tokens so its label can vary without
  // making the borders above and below the prompt vary with it.
  switch (level) {
    case "off":
      return "dim";
    case "minimal":
      return "muted";
    case "low":
      return "mdListBullet";
    case "medium":
      return "toolTitle";
    case "high":
      return "syntaxKeyword";
    case "xhigh":
      return "syntaxVariable";
    case "max":
      return "error";
    default:
      return "thinkingText";
  }
}

function thresholdColor(
  value: number | null | undefined,
  thresholds: { threshold: number; color: ThemeColor }[],
): ThemeColor {
  if (value === null || value === undefined || !Number.isFinite(value))
    return "muted";
  let color = thresholds[0]?.color ?? "text";
  for (const stop of thresholds) {
    if (value >= stop.threshold) color = stop.color;
    else break;
  }
  return color;
}

export function registerStatusBarExtension(pi: ExtensionAPI) {
  let requestRender: (() => void) | undefined;
  let statusFilter: StatusFilter = { mode: "all", hidden: new Set() };
  let visibleSegments: SegmentName[] = readGlobalSegments() ?? DEFAULT_SEGMENTS;
  let mcpUsed = false;
  const seenStatusKeys = new Set<string>();
  const refresh = () => requestRender?.();
  const progress = new FooterProgressEngine(refresh);
  const cost = new CostTracker();
  const dailyCost = new DailyCostTracker();
  const isMcpTool = (toolName: string) => {
    if (toolName === "mcp") return true;
    const sourceInfo = pi.getAllTools().find((tool) => tool.name === toolName)
      ?.sourceInfo;
    return Boolean(
      sourceInfo?.path.includes("pi-mcp-adapter") ||
        sourceInfo?.source.includes("pi-mcp-adapter"),
    );
  };
  const restoreMcpUsage = (ctx: ExtensionContext) => {
    mcpUsed = ctx.sessionManager.getBranch().some((entry) => {
      if (entry.type !== "message") return false;
      if (entry.message.role === "toolResult")
        return isMcpTool(entry.message.toolName);
      if (entry.message.role !== "assistant") return false;
      return entry.message.content.some(
        (content) => content.type === "toolCall" && isMcpTool(content.name),
      );
    });
  };
  const restoreStatusFilter = (ctx: ExtensionContext) => {
    let restoredFilter = readGlobalStatusFilter();
    if (!restoredFilter) {
      for (const entry of ctx.sessionManager.getBranch()) {
        if (
          entry.type === "custom" &&
          (entry.customType === STATUS_FILTER_ENTRY_TYPE ||
            entry.customType === LEGACY_STATUS_FILTER_ENTRY_TYPE)
        ) {
          restoredFilter = parseSerializedStatusFilter(entry.data);
        }
      }
    }
    statusFilter = restoredFilter ?? { mode: "all", hidden: new Set() };
  };
  const persistStatusFilter = () => {
    writeGlobalStatusFilter(statusFilter);
    refresh();
  };
  const setVisibleSegments = (
    segments: readonly SegmentName[],
    ctx?: ExtensionContext,
  ) => {
    const previousProgressVisible = visibleSegments.includes("progress");
    visibleSegments = serializeSegments(segments);
    writeGlobalSegments(visibleSegments);
    const nextProgressVisible = visibleSegments.includes("progress");
    if (previousProgressVisible && !nextProgressVisible) progress.shutdown();
    if (!previousProgressVisible && nextProgressVisible && ctx)
      progress.startSession(ctx.cwd);
    refresh();
  };
  const openSegmentConfigurator = async (ctx: ExtensionContext) => {
    await ctx.ui.custom((tui, theme, _kb, done) => {
      const knownStatusKeys = getKnownStatusKeys(statusFilter, seenStatusKeys);
      const segmentVisibility = new Map(
        ALL_SEGMENTS.map((segment): [SegmentName, boolean] => [
          segment,
          visibleSegments.includes(segment),
        ]),
      );
      let futureShown = statusFilter.mode === "all";
      const statusVisibility = new Map(
        knownStatusKeys.map((key): [string, boolean] => [
          key,
          shouldShowStatus(key, statusFilter),
        ]),
      );
      const persistSegmentsFromVisibility = () => {
        setVisibleSegments(
          ALL_SEGMENTS.filter((segment) => segmentVisibility.get(segment)),
          ctx,
        );
      };
      const persistStatusesFromVisibility = () => {
        if (futureShown) {
          statusFilter = {
            mode: "all",
            hidden: new Set(
              knownStatusKeys.filter((key) => !statusVisibility.get(key)),
            ),
          };
        } else {
          statusFilter = {
            mode: "only",
            shown: new Set(
              knownStatusKeys.filter((key) => statusVisibility.get(key)),
            ),
          };
        }
        persistStatusFilter();
      };

      const segmentItems: SettingItem[] = ALL_SEGMENTS.map(
        (segment): SettingItem => ({
          id: `segment:${segment}`,
          label: SEGMENT_LABELS[segment],
          description: "Footer segment visibility",
          currentValue: segmentVisibility.get(segment) ? "shown" : "hidden",
          values: ["shown", "hidden"],
        }),
      );
      const statusItems: SettingItem[] =
        knownStatusKeys.length > 0
          ? [
              {
                id: "status:__future",
                label: "New extension statuses",
                description:
                  "Default visibility for status keys discovered later",
                currentValue: futureShown ? "shown" : "hidden",
                values: ["shown", "hidden"],
              },
              ...knownStatusKeys.map(
                (key): SettingItem => ({
                  id: `status:${key}`,
                  label: `Status: ${key}`,
                  description: "Extension status visibility",
                  currentValue: statusVisibility.get(key) ? "shown" : "hidden",
                  values: ["shown", "hidden"],
                }),
              ),
            ]
          : [];
      const items: SettingItem[] = [...segmentItems, ...statusItems];

      const container = new Container();
      container.addChild(
        new (class {
          render(_width: number) {
            return [
              theme.fg("accent", theme.bold("status-bar visibility")),
              theme.fg(
                "dim",
                knownStatusKeys.length > 0
                  ? "Footer segments + extension statuses · Enter/Space toggles · Esc closes"
                  : "Footer segments · no extension statuses seen yet · Esc closes",
              ),
              "",
            ];
          }
          invalidate() {}
        })(),
      );

      const settingsList = new SettingsList(
        items,
        Math.min(items.length + 2, 18),
        getSettingsListTheme(),
        (id, newValue) => {
          if (id.startsWith("segment:")) {
            const segment = id.slice("segment:".length);
            if (!isSegmentName(segment)) return;
            segmentVisibility.set(segment, newValue === "shown");
            persistSegmentsFromVisibility();
            return;
          }

          if (id === "status:__future") {
            futureShown = newValue === "shown";
            persistStatusesFromVisibility();
            return;
          }

          if (id.startsWith("status:")) {
            statusVisibility.set(
              id.slice("status:".length),
              newValue === "shown",
            );
            persistStatusesFromVisibility();
          }
        },
        () => done(undefined),
        { enableSearch: true },
      );

      container.addChild(settingsList);

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          settingsList.handleInput?.(data);
          tui.requestRender();
        },
      };
    });
  };
  const openStatusConfigurator = async (ctx: ExtensionContext) => {
    const knownStatusKeys = getKnownStatusKeys(statusFilter, seenStatusKeys);
    if (knownStatusKeys.length === 0) {
      ctx.ui.notify(
        "No extension statuses seen yet. Open /status-bar after another extension calls ctx.ui.setStatus().",
        "info",
      );
      return;
    }

    await ctx.ui.custom((tui, theme, _kb, done) => {
      let futureShown = statusFilter.mode === "all";
      const statusVisibility = new Map(
        knownStatusKeys.map((key) => [
          key,
          shouldShowStatus(key, statusFilter),
        ]),
      );
      const persistFromVisibility = () => {
        if (futureShown) {
          statusFilter = {
            mode: "all",
            hidden: new Set(
              knownStatusKeys.filter((key) => !statusVisibility.get(key)),
            ),
          };
        } else {
          statusFilter = {
            mode: "only",
            shown: new Set(
              knownStatusKeys.filter((key) => statusVisibility.get(key)),
            ),
          };
        }
        persistStatusFilter();
      };

      const items: SettingItem[] = [
        {
          id: "__future",
          label: "New statuses",
          description: "Default visibility for status keys discovered later",
          currentValue: futureShown ? "shown" : "hidden",
          values: ["shown", "hidden"],
        },
        ...knownStatusKeys.map(
          (key): SettingItem => ({
            id: key,
            label: key,
            description: "Extension status visibility",
            currentValue: statusVisibility.get(key) ? "shown" : "hidden",
            values: ["shown", "hidden"],
          }),
        ),
      ];

      const container = new Container();
      container.addChild(
        new (class {
          render(_width: number) {
            return [
              theme.fg("accent", theme.bold("status-bar status visibility")),
              theme.fg("dim", "Enter/Space toggles · Esc closes"),
              "",
            ];
          }
          invalidate() {}
        })(),
      );

      const settingsList = new SettingsList(
        items,
        Math.min(items.length + 2, 15),
        getSettingsListTheme(),
        (id, newValue) => {
          if (id === "__future") {
            futureShown = newValue === "shown";
          } else {
            statusVisibility.set(id, newValue === "shown");
          }
          persistFromVisibility();
        },
        () => done(undefined),
        { enableSearch: true },
      );

      container.addChild(settingsList);

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          settingsList.handleInput?.(data);
          tui.requestRender();
        },
      };
    });
  };

  pi.registerCommand("status-bar", {
    description: "Configure status-bar footer visibility",
    handler: async (args, ctx) => {
      const [section, action, ...rest] = args
        .trim()
        .split(/\s+/)
        .filter(Boolean);
      if (
        !section ||
        section === "config" ||
        section === "configure" ||
        section === "edit"
      ) {
        await openSegmentConfigurator(ctx);
        return;
      }
      if (section === "list" || section === "ls") {
        ctx.ui.notify(
          `status-bar footer: ${describeSegments(visibleSegments)}`,
          "info",
        );
        return;
      }

      if (
        section === "segment" ||
        section === "segments" ||
        section === "footer"
      ) {
        const segments = splitSegmentNames(rest.join(" "));
        if (
          (action === "only" || action === "show" || action === "hide") &&
          segments.length === 0
        ) {
          ctx.ui.notify(`Segments: ${ALL_SEGMENTS.join(", ")}`, "warning");
          return;
        }

        switch (action) {
          case undefined:
          case "config":
          case "configure":
          case "edit":
            await openSegmentConfigurator(ctx);
            return;
          case "list":
          case "ls":
            ctx.ui.notify(
              `status-bar footer: ${describeSegments(visibleSegments)}`,
              "info",
            );
            return;
          case "all":
            setVisibleSegments(ALL_SEGMENTS, ctx);
            break;
          case "none":
            setVisibleSegments([], ctx);
            break;
          case "only":
            setVisibleSegments(segments, ctx);
            break;
          case "hide":
            setVisibleSegments(
              visibleSegments.filter((segment) => !segments.includes(segment)),
              ctx,
            );
            break;
          case "show":
            setVisibleSegments([...visibleSegments, ...segments], ctx);
            break;
          default:
            ctx.ui.notify(
              "Usage: /status-bar [config] or /status-bar segments [list|all|none|only <segments>|show <segments>|hide <segments>]",
              "warning",
            );
            return;
        }

        ctx.ui.notify(
          `status-bar footer: ${describeSegments(visibleSegments)}`,
          "info",
        );
        return;
      }

      if ((section === "status" || section === "statuses") && !action) {
        await openStatusConfigurator(ctx);
        return;
      }

      if (section === "status" || section === "statuses") {
        const keys = splitStatusKeys(rest.join(" "));

        switch (action) {
          case "config":
          case "configure":
          case "edit":
            await openStatusConfigurator(ctx);
            return;
          case "list":
          case "ls": {
            const known = getKnownStatusKeys(statusFilter, seenStatusKeys);
            ctx.ui.notify(
              `status-bar statuses: ${describeStatusFilter(statusFilter)}${known.length > 0 ? `; known: ${known.join(", ")}` : "; known: none yet"}`,
              "info",
            );
            return;
          }
          case "all":
            statusFilter = { mode: "all", hidden: new Set() };
            break;
          case "none":
            statusFilter = { mode: "only", shown: new Set() };
            break;
          case "only":
            statusFilter = { mode: "only", shown: new Set(keys) };
            break;
          case "hide":
            if (statusFilter.mode === "only") {
              for (const key of keys) statusFilter.shown.delete(key);
            } else {
              for (const key of keys) statusFilter.hidden.add(key);
            }
            break;
          case "show":
            if (statusFilter.mode === "only") {
              for (const key of keys) statusFilter.shown.add(key);
            } else {
              for (const key of keys) statusFilter.hidden.delete(key);
            }
            break;
          default:
            ctx.ui.notify(
              "Usage: /status-bar status [list|all|none|only <keys>|show <keys>|hide <keys>]",
              "warning",
            );
            return;
        }

        persistStatusFilter();
        ctx.ui.notify(
          `status-bar statuses: ${describeStatusFilter(statusFilter)}`,
          "info",
        );
        return;
      }

      ctx.ui.notify(
        "Usage: /status-bar [config] or /status-bar segments [list|all|none|only <segments>|show <segments>|hide <segments>] or /status-bar status [list|all|none|only <keys>|show <keys>|hide <keys>]",
        "warning",
      );
    },
  });

  pi.on("model_select", async () => refresh());
  pi.on("thinking_level_select", async () => refresh());
  pi.on("turn_end", async () => refresh());
  pi.on("before_agent_start", async (event, ctx) => {
    if (visibleSegments.includes("progress"))
      progress.recordUserMessage(ctx, event.prompt);
  });
  pi.on("message_update", async (event, ctx) => {
    if (visibleSegments.includes("progress"))
      progress.recordAssistantUpdate(ctx, event.message);
  });
  pi.on("tool_call", async (event, ctx) => {
    if (!mcpUsed && isMcpTool(event.toolName)) {
      mcpUsed = true;
      refresh();
    }
    if (visibleSegments.includes("progress"))
      progress.recordToolCall(ctx, event);
  });
  pi.on("tool_result", async (event, ctx) => {
    if (visibleSegments.includes("progress"))
      progress.recordToolResult(ctx, event);
  });
  pi.on("message_end", async (event, ctx) => {
    if (visibleSegments.includes("cost")) {
      const amount = cost.recordMessage(event.message);
      dailyCost.record(amount);
    }
    if (visibleSegments.includes("progress"))
      progress.recordMessageEnd(ctx, event.message);
    refresh();
  });
  pi.on("session_before_tree", async () => {
    progress.shutdown();
  });
  pi.on("session_tree", async (_event, ctx) => {
    if (visibleSegments.includes("progress")) progress.startSession(ctx.cwd);
    else progress.shutdown();
    dailyCost.setSession(ctx.sessionManager.getSessionId());
    dailyCost.load();
    restoreStatusFilter(ctx);
    restoreMcpUsage(ctx);
    refresh();
  });

  pi.on("session_start", async (_event, ctx) => {
    visibleSegments = readGlobalSegments() ?? DEFAULT_SEGMENTS;
    cost.resetFromSession(ctx);
    dailyCost.setSession(ctx.sessionManager.getSessionId());
    dailyCost.load();
    if (visibleSegments.includes("progress")) progress.startSession(ctx.cwd);
    else progress.shutdown();
    restoreStatusFilter(ctx);
    restoreMcpUsage(ctx);

    if (!ctx.hasUI) return;

    ctx.ui.setFooter((tui, theme, footerData) => {
      requestRender = () => tui.requestRender();

      return {
        dispose() {
          requestRender = undefined;
        },
        invalidate() {},
        render(width: number): string[] {
          // Re-read tiny config during render so threshold edits apply after /reload
          // without restarting the session.
          const colorThresholds = readColorThresholds();
          const modelName = formatModelName(ctx.model?.id);
          const thinkingLevel = String(pi.getThinkingLevel());
          const extensionStatusParts = formatExtensionStatuses(
            footerData?.getExtensionStatuses?.() ?? new Map(),
            statusFilter,
            seenStatusKeys,
            mcpUsed,
          );
          const usage = ctx.getContextUsage();
          // Context color thresholds are absolute token counts (not percent),
          // so the warning colors track real usage regardless of the model's
          // context window size.
          const contextSegmentColor = thresholdColor(
            usage?.tokens,
            colorThresholds.context,
          );

          const contextPercentText = usage
            ? usage.percent !== null
              ? `${usage.percent.toFixed(1)}%`
              : "—%"
            : "—";
          // Layout: "40K/1.0M 12.3%" — the used-token count colors by the
          // token thresholds, the percent by its own percent thresholds, and
          // only the window size stays muted.
          const contextPercentColor = thresholdColor(
            usage?.percent,
            colorThresholds.contextPercent,
          );
          const contextText = usage
            ? `${theme.fg(contextSegmentColor, usage.tokens === null ? "—" : formatTokens(usage.tokens))}${theme.fg("muted", `/${formatTokens(usage.contextWindow)}`)} ${theme.fg(contextPercentColor, contextPercentText)}`
            : theme.fg("muted", contextPercentText);
          const progressText = progress.text();
          const costAmount = cost.amount();
          const costText = cost.text();
          const dayCostText = formatWholeCost(dailyCost.dayAmount());
          const weekCostText = formatWholeCost(dailyCost.weekAmount());

          const extensionStatuses = extensionStatusParts
            ? extensionStatusParts
                .map(({ key, text }) =>
                  theme.fg(key === "mcp" ? "accent" : "text", text),
                )
                .join(` ${theme.fg("dim", EXTENSION_STATUS_SEPARATOR)} `)
            : null;
          const segmentRenderers: Record<SegmentName, string | null> = {
            model: theme.fg("accent", modelName),
            thinking: theme.fg(thinkingColor(thinkingLevel), thinkingLevel),
            context: contextText,
            cost: `${theme.fg(thresholdColor(costAmount, colorThresholds.cost), costText)} ${theme.fg("muted", `· ${dayCostText}d · ${weekCostText}w`)}`,
            progress: progressText ? theme.fg("text", progressText) : null,
            extensions: extensionStatuses,
          };

          // Keep the footer compact so the added cost segment leaves more room for progress text.
          const separator = ` ${theme.fg("dim", SEGMENT_SEPARATOR)} `;
          const line = visibleSegments
            .map((segment) => segmentRenderers[segment])
            .filter((segment): segment is string => segment !== null)
            .join(separator);

          // Add a leading pad so the first segment does not hug the terminal edge.
          return [truncateToWidth(` ${line}`, width)];
        },
      };
    });
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    progress.shutdown();
    if (ctx.hasUI) ctx.ui.setFooter(undefined);
  });
}
