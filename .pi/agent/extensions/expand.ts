/**
 * Add /expand as a typed command alias for Pi's tool-output toggle.
 *
 * This is useful on keyboards/sessions where typing a slash command is easier
 * than remembering or sending the Ctrl+O keybinding.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const COMPACT_READ_STATE = Symbol.for("ivu.pi.compactReadState");

type CompactReadState = {
	enabled: boolean;
};

export default function (pi: ExtensionAPI) {
	pi.registerCommand("expand", {
		description: "Toggle compact collapsed read rendering",
		handler: async (_args, ctx) => {
			const state = getCompactReadState();
			state.enabled = !state.enabled;

			// Re-apply the current expansion value so existing read components re-render.
			ctx.ui.setToolsExpanded(ctx.ui.getToolsExpanded());
			ctx.ui.notify(`Compact read rendering ${state.enabled ? "enabled" : "disabled"}`, "info");
		},
	});
}

function getCompactReadState(): CompactReadState {
	const globalState = globalThis as typeof globalThis & { [COMPACT_READ_STATE]?: CompactReadState };
	globalState[COMPACT_READ_STATE] ??= { enabled: true };
	return globalState[COMPACT_READ_STATE];
}

