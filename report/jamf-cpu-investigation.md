# JamfDaemon high-CPU investigation — session notes

Date: 2026-07-25
Host: `IV-HYR7Y3QT92`
Jamf agent: 11.30.1 (build `t1784555528405`)

## Task
Diagnose high CPU on the Mac, then deep-dive the culprit (JamfDaemon).

## Approach progression
1. `ps -Arceo` to rank processes by CPU → `JamfDaemon` at 40–60%.
2. `ps -p` + `ps -A -m` → process details, thread CPU time (25 min over 42 min wall ≈ ~60% sustained).
3. `log show --predicate 'process == "JamfDaemon"'` → found the runaway loop: ~107k lines/min, all one message.
4. `sed`/`uniq -c` aggregation → confirmed 100% of log volume is a single `NSURLIsPackageKey` ENOENT error, ~2,000/sec.
5. `plutil -p` on launchd plists → `KeepAlive=true` explains why killing won't help; `task.1.plist` shows the 30-min recurring check-in.
6. `fs_usage -w -f filesys <PID>` (sudo) → revealed the real hot path: repeated `tmux` PATH resolution across `/usr/local/bin/tmux`, `/Users/ivu/.bun/bin/tmux`, etc.
7. `strings` on the JamfDaemon binary → found `RestrictedSoftwareMonitor`/`RestrictedSoftwareService` classes and "starting restricted software monitoring" → tied the loop to the Restricted Software feature.
8. `sqlite3 .jmf.sqlite` → confirmed the local DB is plain SQLite (Core Data schema); the actual rule lives in root-only `.jmf_settings.json`.

## Key findings
- Root cause: a Jamf **Restricted Software** rule targeting `tmux`, combined with a JamfDaemon 11.30.1 bug that re-resolves the target binary path on every check instead of caching it.
- The management server / recurring check-ins are healthy — the spin is purely local to the daemon's process monitor.
- Killing the daemon is pointless (`KeepAlive` respawns it); the durable fix is admin-side (remove the rule or upgrade Jamf).

## Mistakes / corrections worth noting
- First `top -l 1` snapshot showed everything at 0.0% CPU — a one-shot sample misses transient spikes; `ps -Arceo` (cumulative) was the right tool.
- Wrong command given: `sudo log config --mode "private_data:on"` — `private_data` is **not** a valid `log config` mode key on this macOS. Correct approach to see real paths is `fs_usage`, not log un-redaction.
- `uniq -c` on raw `fs_usage` output didn't aggregate because every line has a unique timestamp — need to strip timestamp columns first.
- A multi-line bash command with a `DB="…"` variable got mangled by the shell wrapper; switching to `cd` + bare filenames worked.

## Deliverable
A ready-to-send incident report for the MDM/IT admin with evidence, impact, and requested actions. See `jamf-cpu-report.md` in this folder.
