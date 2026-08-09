**Subject:** Jamf Restricted Software rule for `tmux` causing sustained high CPU on managed Mac

Hi,

One of our managed Macs is running a Jamf daemon that's pinned at ~60% CPU due to what looks like a Restricted Software rule targeting `tmux`. Filing this so the rule can be reviewed or Jamf upgraded.

**Affected machine**
- Hostname: `IV-HYR7Y3QT92`
- Jamf Pro agent: 11.30.1 (build `t1784555528405`)
- Daemon path: `/Library/Application Support/JAMF/Jamf.app/Contents/MacOS/JamfDaemon.app/Contents/MacOS/JamfDaemon`

**Symptoms**
- `JamfDaemon` (PID 52361) sustains ~60% CPU (25 min CPU time over 42 min wall).
- ~106,975 unified-log lines per minute, all identical:
  `(AppKit) NSURLIsPackageKey lookup returned Error Domain=NSCocoaErrorDomain Code=260 … "No such file or directory"`
  (~2,000 errors/second)
- `fs_usage` shows the daemon repeatedly resolving the `tmux` binary across `PATH` (`/usr/local/bin/tmux`, `/Users/ivu/.bun/bin/tmux`, …) via `getattrlist`/`lstat64` in a tight loop with no caching.

**Likely cause**
A Restricted Software rule matching `tmux` is configured in Jamf Pro. The `RestrictedSoftwareMonitor` in JamfDaemon 11.30.1 re-resolves the target binary path on every check instead of caching it, producing the loop above. The recurring `jamf policy` check-ins themselves are healthy (`/var/log/jamf.log`: clean ~30-min intervals, last 21:51, ~6 s each), so this is local to the daemon's process monitor, not a server-side policy execution problem.

**Impact**
- One core ~60% utilized continuously; battery/thermals affected.
- ~2,000 log lines/sec to unified logging.

**Requested actions**
1. Review the Restricted Software rules for an entry matching `tmux` and confirm it's intended. If `tmux` shouldn't be banned, remove the rule.
2. If the rule is intended, please file a Jamf support case for the no-cache path-resolution loop in `RestrictedSoftwareMonitor` (agent 11.30.1) and/or schedule a Jamf upgrade.

**What I can't do locally**
The daemon's launchd plist has `KeepAlive=true`, so killing it just respawns it. The restricted-software config lives in `/Library/Application Support/JAMF/.jmf_settings.json` (root-only). The durable fix is on the Jamf admin side.

Happy to run any further diagnostics you'd like.
