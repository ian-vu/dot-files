/**
 * Deterministic text replacements for Pi output, safe file-content writes,
 * and known prose payloads embedded in tool calls.
 *
 * Rules are intentionally applied only to prose or replacement text fields.
 * Exact-match edit inputs, command syntax, paths, search patterns, and URLs are
 * left unchanged so policy enforcement does not silently change execution
 * semantics.
 */

import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

// ======== REPLACEMENT SCOPES ========

const REPLACEMENT_SCOPES = [
  "assistant-message",
  "write-content",
  "edit-new-text",
  "bash-github-body",
] as const;

type ReplacementScope = (typeof REPLACEMENT_SCOPES)[number];

type ReplacementRule = {
  id: string;
  find: string;
  replace: string;
  scopes: readonly ReplacementScope[];
};

// ======== RULES ========

const RULES = [
  {
    id: "no-em-dash",
    find: "\u2014", // `—`
    replace: "-",
    scopes: [
      "assistant-message",
      "write-content",
      "edit-new-text",
      "bash-github-body",
    ],
  },
] satisfies ReplacementRule[];

// ======== EXTENSION HOOKS ========

export default function (pi: ExtensionAPI) {
  pi.on("message_end", async (event) => {
    if (event.message.role !== "assistant") return;

    let changed = false;
    const content = event.message.content.map((part) => {
      if (part.type !== "text") return part;

      const text = applyTextReplacements(part.text, "assistant-message");
      if (text === part.text) return part;

      changed = true;
      const { textSignature: _textSignature, ...unsignedPart } = part;
      return { ...unsignedPart, text };
    });

    if (!changed) return;
    return { message: { ...event.message, content } };
  });

  pi.on("tool_call", async (event) => {
    if (isToolCallEventType("bash", event)) {
      event.input.command = applyBashProseReplacements(event.input.command);
      return;
    }

    if (isToolCallEventType("write", event)) {
      event.input.content = applyTextReplacements(
        event.input.content,
        "write-content",
      );
      return;
    }

    if (isToolCallEventType("edit", event)) {
      for (const edit of event.input.edits) {
        edit.newText = applyTextReplacements(edit.newText, "edit-new-text");
      }
    }
  });
}

// ======== REPLACEMENT ENGINE ========

function applyTextReplacements(text: string, scope: ReplacementScope): string {
  let result = text;

  for (const rule of RULES) {
    if (!rule.scopes.includes(scope) || rule.find.length === 0) continue;
    result = result.split(rule.find).join(rule.replace);
  }

  return result;
}

// ======== BASH PROSE PAYLOADS ========

const GH_COMMENT_COMMAND_PATTERN = String.raw`\bgh\s+(?:pr\s+(?:comment|review)|issue\s+comment)\b`;

// Match shell argument values without rewriting the surrounding command syntax.
const SHELL_ARGUMENT_VALUE_PATTERN =
  String.raw`(?:(?:"(?:\\.|[^"\\])*")|(?:'[^']*')|(?:[^\s;&|]+))`;

const GH_API_BODY_FIELD_PATTERN = new RegExp(
  String.raw`(\bgh\s+api\b[^\n;&|]*?\s(?:-f|-F|--field|--raw-field)(?:=|\s+)body=)` +
    `(${SHELL_ARGUMENT_VALUE_PATTERN})`,
  "g",
);

const GH_BODY_FLAG_PATTERN = new RegExp(
  String.raw`(${GH_COMMENT_COMMAND_PATTERN}[^\n;&|]*?\s(?:--body|-b)(?:=|\s+))` +
    `(${SHELL_ARGUMENT_VALUE_PATTERN})`,
  "g",
);

function applyBashProseReplacements(command: string): string {
  // GitHub comments are user-visible prose, but the command around them is not.
  return command
    .replace(GH_API_BODY_FIELD_PATTERN, replaceShellValue)
    .replace(GH_BODY_FLAG_PATTERN, replaceShellValue);
}

function replaceShellValue(
  _match: string,
  prefix: string,
  value: string,
): string {
  return `${prefix}${applyTextReplacements(value, "bash-github-body")}`;
}
