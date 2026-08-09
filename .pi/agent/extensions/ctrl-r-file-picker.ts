import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function runFzf(cwd: string): string | undefined {
	const stdin = process.stdin as typeof process.stdin & { isRaw?: boolean; setRawMode?: (enabled: boolean) => void };
	const wasRaw = stdin.isRaw === true;

	try {
		// fzf needs the terminal in cooked mode; Pi normally keeps stdin raw for the TUI.
		stdin.setRawMode?.(false);

		const result = spawnSync(
			"sh",
			[
				"-c",
				[
					"candidates=$(mktemp)",
					"selection=$(mktemp)",
					"trap 'rm -f \"$candidates\" \"$selection\"' EXIT",
					"if command -v fd >/dev/null 2>&1; then",
					"  fd --type f --hidden --exclude .git > \"$candidates\";",
					"else",
					"  find . -type f -not -path './.git/*' | sed 's#^./##' > \"$candidates\";",
					"fi",
					"if [ -n \"$TMUX\" ]; then",
					// Anchor the tmux popup to the current pane; fzf --tmux centers in the client when given only width/height.
					"  pane_left=$(tmux display-message -p '#{pane_left}')",
					"  pane_top=$(tmux display-message -p '#{pane_top}')",
					"  width=$(tmux display-message -p '#{pane_width}')",
					"  height=$(tmux display-message -p '#{pane_height}')",
					"  client_height=$(tmux display-message -p '#{client_height}')",
					"  popup_height=$((height * 40 / 100))",
					"  [ \"$popup_height\" -lt 3 ] && popup_height=3",
					"  popup_y=$((client_height - popup_height))",
					// Use current pane width/x, but anchor y against the tmux client bottom.
					"  tmux display-popup -E -x \"$pane_left\" -y \"$popup_y\" -w \"$width\" -h \"$popup_height\" \"fzf --reverse --prompt='' --no-info < \\\"$candidates\\\" > \\\"$selection\\\"\"", 

					"  cat \"$selection\"",
					"else",
					"  fzf --height=40% --reverse --prompt='' --no-info < \"$candidates\"",
					"fi",
				].join("\n"),
			],
			{
				cwd,
				encoding: "utf8",
				stdio: ["inherit", "pipe", "inherit"],
			},
		);

		if (result.status !== 0) return undefined;
		return result.stdout.trim() || undefined;
	} finally {
		if (wasRaw) stdin.setRawMode?.(true);
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerShortcut("ctrl+r", {
		description: "Pick a file with fzf",
		handler: async (ctx) => {
			const selection = runFzf(ctx.cwd);
			if (!selection) return;

			// Prefix with @ so Pi treats the selected path as a file reference.
			ctx.ui.pasteToEditor(`@${selection}`);
		},
	});
}
