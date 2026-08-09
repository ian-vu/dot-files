// Config loading and secret resolution for meeting-sync.
//
// config.json is checked in and holds no secrets. The Notion token lives in
// 1Password and is fetched at runtime via `op read` using an `op://` reference.
// A gitignored local cache (`.cache/`) holds the most recent fetch for
// background/fallback runs (see PLAN.md).

import { readFile } from "node:fs/promises";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Absolute path to the tool root (parent of src/), so the tool works no matter
// where it is invoked from.
export const toolRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

/** Expand a leading ~ to the user's home directory. */
export function expandHome(p) {
  if (p === "~") return homedir();
  if (p.startsWith("~/")) return join(homedir(), p.slice(2));
  return p;
}

/** Resolve a config-relative path against the tool root (absolute paths pass through). */
function resolveFromTool(p) {
  const expanded = expandHome(p);
  return isAbsolute(expanded) ? expanded : join(toolRoot, expanded);
}

/** Load and normalize config.json. */
export async function loadConfig() {
  const raw = await readFile(join(toolRoot, "config.json"), "utf8");
  const cfg = JSON.parse(raw);
  return {
    ...cfg,
    vaultPath: expandHome(cfg.vault),
    // `op://` reference to the Notion token in 1Password (canonical source).
    notionTokenRef: cfg.notionTokenRef ?? "",
    // Local temp cache of the token, for background/fallback runs. Gitignored.
    tokenCachePath: cfg.tokenCacheFile ? resolveFromTool(cfg.tokenCacheFile) : null,
    notionVersion: cfg.notionVersion ?? "2026-03-11",
  };
}

/**
 * Resolve the Notion integration token from 1Password.
 *
 * Canonical source is a 1Password item referenced by `notionTokenRef` in
 * config.json (an `op://...` reference). `op read` fetches it at runtime, so the
 * only secret on disk is the 1Password account auth itself. On a successful
 * fetch the value is also written to a gitignored local cache file so that
 * background runs (launchd, Phase 3) and runs without an active `op` session
 * can still authenticate. The cache is a temp copy, never the source of truth.
 */
export function loadToken(cfg) {
  if (!cfg.notionTokenRef || cfg.notionTokenRef.includes("<")) {
    throw new Error(
      "No 1Password reference configured. Set `notionTokenRef` in config.json to an `op://...`\n" +
        "reference pointing at the Notion integration token item you created in 1Password.",
    );
  }

  // Try the canonical source first: 1Password via the `op` CLI.
  let token = null;
  try {
    const res = spawnSync("op", ["read", cfg.notionTokenRef], { encoding: "utf8" });
    if (res.status === 0 && res.stdout.trim()) {
      token = res.stdout.trim();
    } else {
      const detail = (res.stderr || "").trim();
      console.error(
        `op read failed (status ${res.status ?? "?"})${detail ? ": " + detail : ""}`,
      );
    }
  } catch (err) {
    console.error(`op not available: ${err.message}`);
  }

  if (token) {
    // Refresh the local temp cache so background/fallback runs can use it.
    if (cfg.tokenCachePath) {
      try {
        mkdirSync(dirname(cfg.tokenCachePath), { recursive: true });
        writeFileSync(cfg.tokenCachePath, token + "\n", { mode: 0o600 });
      } catch (err) {
        console.error(`Could not write token cache to ${cfg.tokenCachePath}: ${err.message}`);
      }
    }
    return token;
  }

  // Fallback: a previously cached temp copy (stale, but unblocks offline/daemon runs).
  if (cfg.tokenCachePath && existsSync(cfg.tokenCachePath)) {
    const cached = readFileSync(cfg.tokenCachePath, "utf8").trim();
    if (cached) {
      console.error(
        `Warning: using cached token from ${cfg.tokenCachePath} (may be stale;\n` +
          `run \`just tools meeting-sync refresh-token\` to refresh from 1Password).`,
      );
      return cached;
    }
  }

  throw new Error(
    "Could not get the Notion token from 1Password and no local cache exists.\n" +
      "Sign in to 1Password (`op signin`) or create the item, then run\n" +
      "`just tools meeting-sync refresh-token`.",
  );
}
