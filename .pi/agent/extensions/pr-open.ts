/**
 * `/pr-open` slash command: open the current branch's PR in a browser.
 *
 * Mirrors the `gho` shell alias (`gh pr view --web`) so the same action works
 * from within Pi without dropping to a shell. An optional PR number or URL can
 * be passed (`/pr-open 123`, `/pr-open https://github.com/.../pull/123`); without
 * an arg it opens the PR for the current branch.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pr-open", {
    description: "Open the current branch's PR in a browser (gh pr view --web)",
    handler: async (args, ctx) => {
      const target = args.trim();
      const ghArgs = ["pr", "view"];
      if (target) ghArgs.push(target);
      ghArgs.push("--web");

      // Detached so a slow `gh`/browser launch never blocks the Pi UI.
      const child = spawn("gh", ghArgs, {
        detached: true,
        stdio: "ignore",
      });
      child.unref();

      ctx.ui.notify(
        target
          ? `Opening PR ${target} in browser…`
          : "Opening current branch PR in browser…",
        "info",
      );
    },
  });
}
