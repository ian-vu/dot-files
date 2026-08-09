# status-bar extension module map

This directory reduces AI/human maintenance context for the status-bar extension.
The top-level `../status-bar.ts` is only the Pi-discoverable entrypoint and
immediately delegates here.

Current modules:

- `extension.ts` — Pi command/event/footer orchestration.
- `segments.ts` — footer segment names, separators, parsing, serialization, and descriptions.
- `status-filter.ts` — extension status visibility filters and formatting.
- `config.ts` — persisted config paths, migration fallback, thresholds, and config writes.
- `costs/session-cost.ts` — session cost extraction/tracking.
- `costs/daily-cost.ts` — live daily cost restore/persist.
- `progress/engine.ts` — progress facts, model calls, prompt/sanitizer, and debounce/render orchestration.

Concern map for targeted maintenance:

| Task | Files to read |
| --- | --- |
| Footer segment order/rendering | `extension.ts`, `segments.ts` |
| `/status-bar` command/config UI | `extension.ts`, `segments.ts`, `status-filter.ts` |
| Config and threshold persistence | `config.ts` |
| Cost behavior | `costs/session-cost.ts`, `costs/daily-cost.ts` |
| Progress wording/model/debounce | `progress/engine.ts` |
| Extension status filtering | `status-filter.ts` |

Behavior-preservation invariants:

- Keep legacy `PI_BAR_*` environment variable compatibility.
- Keep `~/.pi/agent/pi-bar.json` as read-only migration fallback.
- Keep runtime daily cost state out of committed/stowed config unless the current implementation intentionally stores a daily config value.
- Keep local imports using `.js` specifiers for NodeNext/Pi loader compatibility.
- Keep the top-level extension entrypoint small with `export default` near the top.
