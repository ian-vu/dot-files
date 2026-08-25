#!/usr/bin/env python3
"""tmux-sidebar: minimal always-visible tmux session list with Pi agent status.

One renderer runs per tmux window (spawned by sidebar-ensure.sh), but only one
renderer holds the collector lock. That collector polls tmux, reads the status
files Pi's tmux-notify extension writes to /tmp/tmux-sidebar/<pane_id>.json,
and atomically publishes a shared snapshot. Other renderers read that cache;
hidden renderers block until their window is selected. Keyboard focus and
terminal rendering remain per-instance.

Status protocol (see .ignore/reports/tmux-sidebar-spec.md):
  - state "running" / "waiting" / "done"; idle is the absence of a file.
  - "running"/"waiting" files whose pid is dead are reaped (crash cleanup);
    "done" files outlive the process by design and are cleared by
    clear-bell.sh when the pane is focused.

Python 3 stdlib only: subprocess polling, raw-terminal input, ANSI redraws.
"""

import fcntl
import json
import os
import re
import select
import signal
import subprocess
import sys
import termios
import time
import tty
import unicodedata

STATUS_DIR = "/tmp/tmux-sidebar"
COLLECTOR_LOCK_PATH = os.path.join(STATUS_DIR, ".collector.lock")
CACHE_PATH = os.path.join(STATUS_DIR, ".collector-cache.json")
CACHE_VERSION = 1
HIBERNATING_OPTION = "@tmux_sidebar_hibernating"
CONFIG_PATH = os.path.expanduser("~/.config/tmux-sidebar/config.json")
# The unit separator cannot appear in session names, so it is a safe delimiter
# for multi-field tmux format queries.
SEP = "\x1f"

DEFAULT_CONFIG = {
    "width": 32,
    "keys": {
        "down": "j",
        "up": "k",
        "switch": "enter",
        "kill": "x",
        "clear": "r",
        "resize": "w",
        "quit": "q",
    },
    "tick_seconds": 1.0,
    "elapsed_alert_minutes": 10,
}

# Aggregation priority: a blocked agent (waiting) outranks a working one.
STATE_PRIORITY = {"waiting": 3, "running": 2, "done": 1, "idle": 0}
GLYPHS = {"waiting": "❗", "running": "⚡", "done": "✓", "idle": "○"}

# ANSI styles (plain codes; no curses dependency).
RESET = "\x1b[0m"
DIM = "\x1b[2m"
BOLD = "\x1b[1m"
RED = "\x1b[31m"
GREEN = "\x1b[32m"
YELLOW = "\x1b[33m"
CYAN = "\x1b[36m"
WHITE = "\x1b[97m"
ORANGE = "\x1b[38;2;255;150;108m"
CURRENT_STYLE = "\x1b[1;38;2;27;29;43;48;2;130;170;255m"
# Keep keyboard selection distinct from the blue current-session highlight.
FOCUSED_STYLE = "\x1b[48;2;59;66;97m"
PROMPT_STYLE = "\x1b[48;2;27;29;43m"
MOUSE_ENABLE = "\x1b[?1000h\x1b[?1006h"
MOUSE_DISABLE = "\x1b[?1006l\x1b[?1000l"


def load_config():
    """Merge user config over defaults; missing keys fall back per-field."""
    cfg = json.loads(json.dumps(DEFAULT_CONFIG))
    try:
        with open(CONFIG_PATH, encoding="utf-8") as fh:
            user = json.load(fh)
    except (OSError, ValueError):
        return cfg
    for key, value in user.items():
        if key == "keys" and isinstance(value, dict):
            cfg["keys"].update({k: str(v) for k, v in value.items()})
        elif key in cfg:
            cfg[key] = value
    return cfg


def tmux(*args):
    """Run a tmux command; return stdout or None on failure."""
    try:
        out = subprocess.run(
            ("tmux",) + args,
            capture_output=True,
            text=True,
            timeout=5,
            check=True,
        )
        return out.stdout
    except (subprocess.SubprocessError, OSError):
        return None


def switch_session(session):
    """Switch exactly to `session`, then focus its pane right of the sidebar."""
    tmux("switch-client", "-t", "=" + session)
    out = tmux(
        "list-panes",
        "-t",
        "=" + session,
        "-F",
        "#{pane_id}" + SEP + "#{pane_title}",
    )
    if not out:
        return
    for line in out.splitlines():
        pane_id, _, title = line.partition(SEP)
        if title == "tmux-sidebar":
            tmux("select-pane", "-t", pane_id, "-R")
            return


def kill_session(session):
    """Kill exactly `session`."""
    if session:
        tmux("kill-session", "-t", "=" + session)


def pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except (PermissionError, OSError, TypeError, ValueError):
        # Permission errors mean the pid exists but belongs to another user.
        return True


def read_status_files(pane_session=None):
    """Read status files and reap running/waiting files with dead pids.

    Returns {session_name: [entry, ...]}. Session names are re-resolved from
    the pane map collected in the same global tmux query. The fallback query
    keeps direct callers compatible.
    """
    entries = []
    try:
        names = os.listdir(STATUS_DIR)
    except OSError:
        return {}

    for name in names:
        # Dotfiles are collector internals, not Pi pane status entries.
        if name.startswith(".") or not name.endswith(".json"):
            continue
        path = os.path.join(STATUS_DIR, name)
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError):
            continue
        state = data.get("state")
        if state not in ("running", "waiting", "done"):
            continue
        # Crash reaper: a running/waiting agent whose process died leaves
        # garbage. Done outlives the process by design (cleared on focus).
        if state in ("running", "waiting") and not pid_alive(data.get("pid")):
            try:
                os.unlink(path)
            except OSError:
                pass
            continue
        entries.append(data)

    if not entries:
        return {}

    # Re-resolve session names from live panes so renamed sessions attribute
    # their status files correctly. The collector normally supplies this map.
    if pane_session is None:
        pane_session = {}
        out = tmux("list-panes", "-a", "-F", "#{pane_id}" + SEP + "#{session_name}")
        if out:
            for line in out.splitlines():
                pane_id, _, session = line.partition(SEP)
                pane_session[pane_id] = session

    by_session = {}
    for data in entries:
        session = pane_session.get(data.get("pane_id"), data.get("session"))
        if not session:
            continue
        by_session.setdefault(session, []).append(data)
    return by_session


def clear_session_status(session):
    """Delete the status files for every pane in `session` so the sidebar
    drops stale symbols for that session. Files are named `<pane_id>.json`
    with the leading % sigil stripped (see clear-bell.sh); list-panes -s
    gives the session's pane ids. Used by the `r` key to reset a session
    whose symbols are wrong (e.g. a "done" that won't clear, or a
    running/waiting marker left behind by a crashed agent).
    """
    if not session:
        return
    out = tmux("list-panes", "-s", "-t", session, "-F", "#{pane_id}")
    if not out:
        return
    for pane_id in out.splitlines():
        pane_id = pane_id.strip()
        if not pane_id:
            continue
        name = pane_id[1:] if pane_id.startswith("%") else pane_id
        try:
            os.unlink(os.path.join(STATUS_DIR, name + ".json"))
        except OSError:
            pass


def collect_pane_inventory():
    """Collect session order, cwd, and pane ownership in one tmux query."""
    out = tmux(
        "list-panes",
        "-a",
        "-F",
        "#{pane_id}" + SEP + "#{session_name}" + SEP + "#{pane_current_path}",
    )
    session_names = []
    session_cwds = {}
    pane_session = {}
    for line in (out or "").splitlines():
        fields = line.split(SEP, 2)
        if len(fields) != 3:
            continue
        pane_id, session, cwd = fields
        pane_session[pane_id] = session
        if session not in session_cwds:
            session_names.append(session)
            session_cwds[session] = cwd or None
        elif not session_cwds[session] and cwd:
            session_cwds[session] = cwd
    return session_names, session_cwds, pane_session


def collect_client_state():
    """Return current session, focused panes, and client-visible windows."""
    out = tmux(
        "list-clients",
        "-F",
        "#{session_name}" + SEP + "#{pane_id}" + SEP + "#{window_id}",
    )
    current = ""
    focused_panes = set()
    visible_windows = set()
    for line in (out or "").splitlines():
        fields = line.split(SEP, 2)
        if len(fields) != 3:
            continue
        session, pane_id, window_id = fields
        if not current:
            current = session
        if pane_id:
            focused_panes.add(pane_id)
        if window_id:
            visible_windows.add(window_id)
    return current, focused_panes, visible_windows


# Worktree detection is cached because `git rev-parse` per session per tick
# would be wasteful; cwds change rarely.
_worktree_cache = {}
WORKTREE_CACHE_TTL = 10.0


def repo_info(cwd):
    """(main_repo_root, is_worktree) for cwd, or (None, False) outside git.

    The main repo root is the group key: it is identical for the main
    checkout and every linked worktree of the same repository, so sessions in
    `~/repo` and `~/repo-wt/{a,b}` all group together regardless of where the
    worktree directories live on disk. Linked worktrees have their git dir at
    <main>/.git/worktrees/<name>; the main checkout's is <main>/.git.
    """
    if not cwd:
        return (None, False)
    now = time.time()
    cached = _worktree_cache.get(cwd)
    if cached and now - cached[0] < WORKTREE_CACHE_TTL:
        return cached[1]
    result = (None, False)
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--absolute-git-dir"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if out.returncode == 0:
            git_dir = out.stdout.strip()
            marker = "/.git/worktrees/"
            if marker in git_dir:
                result = (git_dir.split(marker, 1)[0], True)
            elif git_dir.endswith("/.git"):
                result = (git_dir[: -len("/.git")], False)
            # Bare repos and other layouts stay ungrouped.
    except (subprocess.SubprocessError, OSError):
        pass
    _worktree_cache[cwd] = (now, result)
    return result


def format_elapsed(seconds):
    """Compact elapsed label: 45s, 3m, 1h12m."""
    seconds = max(0, int(seconds))
    if seconds < 60:
        return f"{seconds}s"
    minutes, _ = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes}m"
    hours, minutes = divmod(minutes, 60)
    return f"{hours}h{minutes}m" if minutes else f"{hours}h"


class Session:
    __slots__ = (
        "name",
        "state",
        "state_ts",
        "cwd",
        "group",
        "is_worktree",
    )

    def __init__(self, name):
        self.name = name
        self.state = "idle"
        self.state_ts = 0
        self.cwd = None
        self.group = None
        self.is_worktree = False


def collect():
    """Build one global snapshot using one pane and one client query."""
    session_names, session_cwds, pane_session = collect_pane_inventory()
    status = read_status_files(pane_session)
    sessions = []
    for name in session_names:
        sess = Session(name)
        files = status.get(name, [])
        if files:
            best = max(files, key=lambda f: STATE_PRIORITY.get(f.get("state"), 0))
            sess.state = best.get("state", "idle")
            sess.state_ts = best.get("ts", 0) or 0
        sess.cwd = session_cwds.get(name)
        sess.group, sess.is_worktree = repo_info(sess.cwd)
        sessions.append(sess)

    # Client state cannot be derived from this process's TMUX_PANE: that would
    # make every renderer report its own session and focus.
    current, focused_panes, visible_windows = collect_client_state()
    counts = {
        "running": sum(1 for s in sessions if s.state in ("running", "waiting")),
        "done": sum(1 for s in sessions if s.state == "done"),
    }
    return sessions, current, counts, focused_panes, visible_windows


def snapshot_payload(snapshot):
    """Convert a runtime snapshot to its versioned JSON representation."""
    sessions, current, counts, focused_panes, visible_windows = snapshot
    return {
        "version": CACHE_VERSION,
        "collected_at": time.time(),
        "sessions": [
            {
                "name": sess.name,
                "state": sess.state,
                "state_ts": sess.state_ts,
                "cwd": sess.cwd,
                "group": sess.group,
                "is_worktree": sess.is_worktree,
            }
            for sess in sessions
        ],
        "current": current,
        "counts": counts,
        "focused_panes": sorted(focused_panes),
        "visible_windows": sorted(visible_windows),
    }


def snapshot_from_payload(payload):
    """Validate and rebuild a runtime snapshot from the shared cache."""
    if not isinstance(payload, dict) or payload.get("version") != CACHE_VERSION:
        raise ValueError("unsupported collector cache")
    raw_sessions = payload.get("sessions")
    if not isinstance(raw_sessions, list):
        raise ValueError("invalid sessions")
    sessions = []
    for item in raw_sessions:
        if not isinstance(item, dict) or not isinstance(item.get("name"), str):
            raise ValueError("invalid session")
        state = item.get("state", "idle")
        if state not in STATE_PRIORITY:
            raise ValueError("invalid state")
        sess = Session(item["name"])
        sess.state = state
        sess.state_ts = float(item.get("state_ts", 0) or 0)
        for field in ("cwd", "group"):
            value = item.get(field)
            if value is not None and not isinstance(value, str):
                raise ValueError("invalid session path")
            setattr(sess, field, value)
        sess.is_worktree = bool(item.get("is_worktree", False))
        sessions.append(sess)

    current = payload.get("current", "")
    counts = payload.get("counts", {})
    focused_panes = payload.get("focused_panes", [])
    visible_windows = payload.get("visible_windows", [])
    if not isinstance(current, str) or not isinstance(counts, dict):
        raise ValueError("invalid collector state")
    if not all(isinstance(value, str) for value in focused_panes):
        raise ValueError("invalid focused panes")
    if not all(isinstance(value, str) for value in visible_windows):
        raise ValueError("invalid visible windows")
    normalized_counts = {
        "running": int(counts.get("running", 0)),
        "done": int(counts.get("done", 0)),
    }
    return sessions, current, normalized_counts, set(focused_panes), set(visible_windows)


def open_collector_lock():
    """Open the stable lock inode shared by every renderer."""
    os.makedirs(STATUS_DIR, mode=0o700, exist_ok=True)
    return os.open(COLLECTOR_LOCK_PATH, os.O_RDWR | os.O_CREAT, 0o600)


def try_claim_collector(lock_fd):
    """Claim collector leadership without blocking another renderer."""
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return True
    except BlockingIOError:
        return False


def publish_snapshot(snapshot):
    """Atomically replace the cache so readers never see partial JSON."""
    payload = snapshot_payload(snapshot)
    temp_path = os.path.join(STATUS_DIR, f".collector-cache.{os.getpid()}.tmp")
    try:
        fd = os.open(temp_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, ensure_ascii=False, separators=(",", ":"))
        os.replace(temp_path, CACHE_PATH)
    finally:
        try:
            os.unlink(temp_path)
        except OSError:
            pass


def read_snapshot():
    """Read a complete shared snapshot, or None if no valid cache exists."""
    try:
        with open(CACHE_PATH, encoding="utf-8") as fh:
            return snapshot_from_payload(json.load(fh))
    except (OSError, ValueError, TypeError):
        return None


def drain_fd(fd):
    """Drain pending wake bytes without blocking."""
    while True:
        try:
            if not os.read(fd, 4096):
                return
        except BlockingIOError:
            return
        except OSError:
            return


def hibernate_renderer(own_pane, own_window, wake_read):
    """Block a hidden follower until tmux selects its window or input arrives.

    Returns True after actually blocking and waking. False means a final live
    check found the renderer visible (or could not determine visibility), so
    the caller should keep it active and retry on the normal cache tick.

    The pane option is set before the final visibility check. The selection
    hook can therefore signal the self-pipe without racing the transition into
    select(), while the final list-clients query handles selection just before
    the option was set.
    """
    drain_fd(wake_read)
    tmux("set-option", "-p", "-t", own_pane, HIBERNATING_OPTION, "1")
    try:
        clients = tmux("list-clients", "-F", "#{window_id}")
        if clients is None:
            return False
        if own_window in set(clients.splitlines()):
            return False
        ready, _, _ = select.select([sys.stdin, wake_read], [], [])
        if wake_read in ready:
            drain_fd(wake_read)
        return True
    finally:
        tmux("set-option", "-pu", "-t", own_pane, HIBERNATING_OPTION)


def build_rows(sessions):
    """Flatten sessions into render rows, grouping a repo's main checkout
    with its worktree sessions.

    Row: (kind, session_or_None, label, rail) where kind is "session",
    "group", or "spacer" (blank gap line between every row; inside a group
    the spacer carries the │ rail so the group still reads connected). A group
    renders whenever it contains a linked worktree, including a lone worktree;
    plain sessions that happen to sit in the same repo stay separate rows.
    Inside a group, the repo's own session - the
    non-worktree one whose name matches the repo directory - renders as
    "root" (the header already carries the repo name); other sessions that
    merely have their cwd in the main checkout keep their names. Grouped
    rows keep tmux natural order anchored at the first member.
    """
    group_members = {}
    for sess in sessions:
        if sess.group:
            group_members.setdefault(sess.group, []).append(sess)

    rows = []
    emitted_groups = set()

    def add_block(block):
        if rows:
            rows.append(("spacer", None, "", ""))
        rows.extend(block)

    for sess in sessions:
        members = group_members.get(sess.group) if sess.group else None
        grouped = members and any(m.is_worktree for m in members)
        if grouped:
            if sess.group in emitted_groups:
                continue
            emitted_groups.add(sess.group)
            repo_name = os.path.basename(sess.group)
            block = [("group", None, repo_name, "")]
            for i, member in enumerate(members):
                # Railed spacer between children (and after the header) keeps
                # the vertical line unbroken through the gaps.
                block.append(("spacer", None, "", "│"))
                rail = "╰" if i == len(members) - 1 else "│"
                label = member.name
                if not member.is_worktree and member.name == repo_name:
                    # Repeat the root session name and put the home symbol after it.
                    label = f"{member.name} ⌂"
                elif member.is_worktree:
                    # Worktree sessions follow the <repo>/wt/<name> naming
                    # convention; the repo is already the group header, so
                    # show only the worktree part.
                    prefix = repo_name + "/wt/"
                    if label.startswith(prefix):
                        label = label[len(prefix):]
                block.append(("session", member, label, rail))
            add_block(block)
        else:
            add_block([("session", sess, sess.name, "")])
    return rows


def current_row_index(rows, current):
    """Row index of the client's current session, or None if absent."""
    for idx, (kind, sess, _label, _rail) in enumerate(rows):
        if kind == "session" and sess.name == current:
            return idx
    return None


def visible_len(text):
    """Terminal cell width, ignoring ANSI escapes."""
    plain = re.sub(r"\x1b\[[0-9;]*m", "", text)
    return sum(
        2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        for char in plain
    )


def truncate(name, limit):
    """Truncate plain text to a terminal-cell width."""
    if limit <= 0:
        return ""
    if visible_len(name) <= limit:
        return name

    result = []
    used = 0
    for char in name:
        char_width = 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        if used + char_width + 1 > limit:
            break
        result.append(char)
        used += char_width
    return "".join(result) + "…"


def prompt_box(title, message, hint, width):
    """Build an orange floating prompt sized to the sidebar pane."""
    box_width = max(2, width - 2)
    inner_width = box_width - 2

    def content(text, style=""):
        side_padding = 1 if inner_width >= 2 else 0
        text_width = max(0, inner_width - side_padding * 2)
        text = truncate(text, text_width)
        trailing = " " * max(0, text_width - visible_len(text) + side_padding)
        return (
            f"{PROMPT_STYLE}{ORANGE}│{RESET}"
            f"{PROMPT_STYLE}{style}{' ' * side_padding}{text}{trailing}{RESET}"
            f"{PROMPT_STYLE}{ORANGE}│{RESET}"
        )

    horizontal = "─" * inner_width
    return [
        f"{PROMPT_STYLE}{ORANGE}╭{horizontal}╮{RESET}",
        content(title, BOLD + WHITE),
        content(message, WHITE),
        content(hint, DIM + WHITE),
        f"{PROMPT_STYLE}{ORANGE}╰{horizontal}╯{RESET}",
    ]


def overlay_prompt(lines, box, width):
    """Center a prompt over rendered content without leaving stale cells."""
    if not lines:
        return lines
    visible_box = box[: len(lines)]
    top = max(0, (len(lines) - len(visible_box)) // 2)
    box_width = visible_len(visible_box[0])
    left = max(0, (width - box_width) // 2)
    right = max(0, width - left - box_width)
    for offset, box_line in enumerate(visible_box):
        lines[top + offset] = f"{' ' * left}{box_line}{' ' * right}"
    return lines


def render(
    rows,
    current,
    counts,
    focus_idx,
    cfg,
    width,
    height,
    resize_width,
    confirm_session,
):
    """Render the sidebar, including any active resize or kill prompt.

    resize_width is the in-progress resize target, or None outside resize
    mode. confirm_session is the session awaiting a y/n kill response.
    focus_idx is None when the sidebar pane itself is not focused: the ›
    marker only makes sense while keys actually reach this pane.
    """
    resize_mode = resize_width is not None
    alert_secs = cfg["elapsed_alert_minutes"] * 60
    now = time.time()
    lines = []

    # Keep running / unseen-done counts right-aligned without a header label.
    status = []
    status_plain = []
    if counts["running"]:
        status.append(f"{YELLOW}⚡{counts['running']}{RESET}")
        status_plain.append(f"⚡{counts['running']}")
    if counts["done"]:
        status.append(f"{GREEN}✓{counts['done']}{RESET}")
        status_plain.append(f"✓{counts['done']}")

    right = "  ".join(status)
    right_plain = "  ".join(status_plain)
    if visible_len(right) > width and len(status) > 1:
        right = "".join(status)
        right_plain = "".join(status_plain)
    if visible_len(right) > width:
        right_plain = truncate(right_plain, width)
        right = f"{YELLOW}{right_plain}{RESET}"

    pad = max(0, width - visible_len(right))
    lines.append(f"{' ' * pad}{right}")
    lines.append("")

    for idx, (kind, sess, label, rail) in enumerate(rows):
        focused = idx == focus_idx
        if kind == "spacer":
            # Railed spacers continue the group's vertical line through the
            # gap; the two leading cells mirror the marker column.
            lines.append(f"  {DIM}{rail}{RESET}" if rail else "")
            continue
        if kind == "group":
            # Group header carries the highest-priority aggregate glyph of its
            # children (computed by scanning subsequent railed rows).
            child_states = []
            for k2, s2, _l2, r2 in rows[idx + 1 :]:
                if k2 == "spacer" and r2:
                    continue  # railed gap inside the group
                if k2 != "session" or not r2:
                    break
                child_states.append(s2.state)
            agg = max(child_states, key=lambda s: STATE_PRIORITY[s], default="idle")
            glyph = GLYPHS[agg]
            prefix = f"{glyph} " if glyph else ""
            name = truncate(label, width - 3 - visible_len(prefix))
            lines.append(f"  {DIM}{prefix}{name}{RESET}")
            continue

        marker = "›" if focused else " "
        current_row = sess.name == current
        themed_current = current_row and not focused
        row_style = (
            FOCUSED_STYLE if focused else CURRENT_STYLE if current_row else ""
        )
        row_reset = RESET + row_style
        glyph = GLYPHS[sess.state]
        glyph_style = "" if themed_current else {
            "waiting": RED,
            "running": YELLOW,
            "done": GREEN,
            "idle": DIM,
        }[sess.state]

        elapsed_label = ""
        elapsed_style = "" if themed_current else DIM
        if sess.state in ("running", "waiting") and sess.state_ts:
            elapsed = now - sess.state_ts
            elapsed_label = f"[~{format_elapsed(elapsed)}]"
            # An agent running/blocked past the alert threshold is stuck or
            # forgotten; make it loud without overriding the current-row theme.
            if elapsed >= alert_secs and not themed_current:
                elapsed_style = RED
        elif sess.state == "done" and sess.state_ts:
            elapsed_label = f"[{format_elapsed(now - sess.state_ts)} ago]"

        indent_style = "" if themed_current else DIM
        indent = f"{indent_style}{rail}{row_reset} " if rail else ""
        # Keep the state before the session name and align age at the right edge.
        prefix_cells = 2 + (2 if rail else 0)  # marker+space (+rail+space)
        if glyph:
            prefix_cells += visible_len(glyph) + 1
        suffix_cells = visible_len(elapsed_label)
        suffix_gap = 1 if elapsed_label else 0
        right_margin = 1
        # Hide age before sacrificing the entire name in unusually narrow panes.
        if elapsed_label and width - prefix_cells - suffix_gap - suffix_cells - right_margin < 1:
            elapsed_label = ""
            suffix_cells = 0
            suffix_gap = 0
        name_limit = width - prefix_cells - suffix_gap - suffix_cells - right_margin
        # label, not sess.name: grouped main checkouts display as "root".
        name = truncate(label, name_limit)

        # Match the theme's active window with bold dark text. Other agent rows
        # use a solid white name, while idle rows recede until selected.
        if themed_current:
            name_style = ""
        elif focused:
            name_style = (WHITE if sess.state != "idle" else "") + BOLD
        elif sess.state == "idle":
            name_style = DIM
        else:
            name_style = WHITE

        marker_style = ("" if themed_current else CYAN) + (BOLD if focused else "")
        line = f"{row_style}{marker_style}{marker}{row_reset} {indent}"
        if glyph:
            line += f"{glyph_style}{glyph}{row_reset} "
        line += f"{name_style}{name}{row_reset}"
        line_cells = prefix_cells + visible_len(name)
        if elapsed_label:
            gap = max(suffix_gap, width - right_margin - suffix_cells - line_cells)
            line += f"{' ' * gap}{elapsed_style}{elapsed_label}{row_reset}"
            line_cells += gap + suffix_cells
        if current_row or focused:
            line += " " * max(0, width - line_cells)
        lines.append(line + RESET)

    # Keep the normal controls pinned to the bottom. Active interactions are
    # drawn as floating prompts over the content instead of hiding in this
    # narrow footer.
    keys = cfg["keys"]
    footer_rule = f"{DIM}{'─' * max(0, width - 2)}{RESET}"
    footer_text = (
        f" click/⏎ go  {keys['down']}/{keys['up']} move  "
        f"{keys['kill']} kill  {keys['clear']} clear  "
        f"{keys['resize']} width  {keys['quit']} quit"
    )
    footer = f"{DIM}{truncate(footer_text, max(0, width - 1))}{RESET}"

    # Reserve the header and footer before clipping session rows. This keeps
    # the header visible even when a very short pane cannot fit a session row.
    if height <= 1:
        lines = lines[:1]
    elif height == 2:
        lines = [lines[0], footer]
    else:
        content_height = height - 3
        content = lines[1 : 1 + content_height]
        content.extend([""] * (content_height - len(content)))
        lines = [lines[0], *content, f" {footer_rule}", footer]

    if confirm_session is not None:
        lines = overlay_prompt(
            lines,
            prompt_box(
                "Kill session?",
                confirm_session,
                "y confirm · n/Esc cancel",
                width,
            ),
            width,
        )
    elif resize_mode:
        lines = overlay_prompt(
            lines,
            prompt_box(
                "Resize sidebar",
                f"Width: {resize_width}",
                "←/→ adjust · Enter/Esc done",
                width,
            ),
            width,
        )

    # Home, then each line followed by clear-to-eol. No newline after the last
    # line: writing past the bottom row would scroll the frame up by one.
    body = "\x1b[K\r\n".join(lines)
    return f"\x1b[H{body}\x1b[K\x1b[J"


# Pending input bytes. Multiple keys can queue while a slow poll tick runs;
# reading them in one os.read and returning only the first would drop or
# mangle the rest, so parsing pops exactly one key per call from this buffer.
_input_buffer = b""


def _pop_key():
    """Pop one normalized key or mouse event, or None if incomplete."""
    global _input_buffer
    if not _input_buffer:
        return None
    if _input_buffer[:1] == b"\x1b":
        # SGR mouse sequence: ESC [ < button ; column ; row M/m. tmux
        # forwards these through its default MouseDown1Pane binding once the
        # application enables mouse reporting.
        if _input_buffer.startswith(b"\x1b[<"):
            match = re.match(rb"^\x1b\[<(\d+);(\d+);(\d+)([Mm])", _input_buffer)
            if match:
                _input_buffer = _input_buffer[match.end() :]
                button, column, row, action = match.groups()
                if action == b"M" and int(button) == 0:
                    return ("mouse-down", int(column), int(row))
                return "mouse"
            if re.fullmatch(rb"\x1b\[<[0-9;]*", _input_buffer):
                return None
        # CSI/SS3 arrow sequences: ESC [ C / ESC O C etc.
        if len(_input_buffer) >= 3 and _input_buffer[1:2] in (b"[", b"O"):
            seq, _input_buffer = _input_buffer[:3], _input_buffer[3:]
            final = seq[2:3]
            if final == b"C":
                return "right"
            if final == b"D":
                return "left"
            if final == b"A":
                return "arrow-up"
            if final == b"B":
                return "arrow-down"
            return "unknown"
        if len(_input_buffer) == 1:
            _input_buffer = b""
            return "escape"
        # ESC followed by a non-sequence byte: treat as Escape, keep the rest.
        _input_buffer = _input_buffer[1:]
        return "escape"
    ch, _input_buffer = _input_buffer[:1], _input_buffer[1:]
    if ch in (b"\r", b"\n"):
        return "enter"
    return ch.decode(errors="replace")


def read_key(timeout, wake_fd=None):
    """Return one normalized key within timeout, or None on tick/wake."""
    global _input_buffer
    key = _pop_key()
    if key is not None:
        return key
    inputs = [sys.stdin]
    if wake_fd is not None:
        inputs.append(wake_fd)
    ready, _, _ = select.select(inputs, [], [], timeout)
    if wake_fd is not None and wake_fd in ready:
        drain_fd(wake_fd)
    if sys.stdin not in ready:
        return None
    _input_buffer += os.read(sys.stdin.fileno(), 64)
    # A bare ESC might be the head of an arrow sequence whose tail is still in
    # flight; wait briefly for the continuation before parsing.
    if _input_buffer == b"\x1b":
        ready, _, _ = select.select([sys.stdin], [], [], 0.02)
        if ready:
            _input_buffer += os.read(sys.stdin.fileno(), 64)
    return _pop_key()


def terminal_width(cfg):
    try:
        return os.get_terminal_size().columns
    except OSError:
        return cfg["width"]


def terminal_height():
    try:
        return os.get_terminal_size().lines
    except OSError:
        return 24


def apply_width(own_pane, width):
    """Resize this pane and update the global width authority so
    sidebar-repair.sh and future spawns keep the chosen width."""
    tmux("set", "-g", "@tmux_sidebar_width", str(width))
    if own_pane:
        tmux("resize-pane", "-t", own_pane, "-x", str(width))


def set_repair_pause(paused):
    """Gate sidebar-repair.sh while the user adjusts width interactively.
    Each resize-pane fires tmux resize hooks; without the pause every sidebar
    pane would be repaired per keypress, fanning out subprocess storms."""
    if paused:
        tmux("set", "-g", "@tmux_sidebar_repair_pause", "1")
    else:
        tmux("set", "-gu", "@tmux_sidebar_repair_pause")
        # One deferred repair converges the other windows' sidebars to the
        # final width now that the interactive adjustment is finished.
        repair = os.path.expanduser("~/.config/tmux/scripts/sidebar-repair.sh")
        try:
            subprocess.Popen(
                [repair],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError:
            pass


def main():
    cfg = load_config()
    # Identify this pane so ensure/repair hooks can find sidebar panes by
    # title. Target TMUX_PANE explicitly: an untargeted select-pane titles the
    # client's *current* pane, which is the user's pane, not this one.
    own_pane = os.environ.get("TMUX_PANE")
    own_window = ""
    if own_pane:
        tmux("select-pane", "-t", own_pane, "-T", "tmux-sidebar")
        own_window = (
            tmux("display-message", "-p", "-t", own_pane, "#{window_id}") or ""
        ).strip()

    if not sys.stdin.isatty():
        print("tmux-sidebar must run inside a tmux pane", file=sys.stderr)
        return 1

    fd = sys.stdin.fileno()
    old_attrs = termios.tcgetattr(fd)
    lock_fd = open_collector_lock()
    wake_read, wake_write = os.pipe()
    os.set_blocking(wake_read, False)
    os.set_blocking(wake_write, False)
    resized = [True]

    def wake_renderer(_sig, _frame):
        try:
            os.write(wake_write, b"w")
        except (BlockingIOError, OSError):
            pass

    def on_resize(_sig, _frame):
        resized[0] = True
        wake_renderer(_sig, _frame)

    signal.signal(signal.SIGUSR1, wake_renderer)
    signal.signal(signal.SIGWINCH, on_resize)

    focus_idx = 0
    resize_mode = False
    # Target width during resize mode. Tracked locally because the pane's
    # observed terminal size lags resize-pane by a frame; reading it back per
    # keypress would make rapid ←/→ presses fight the previous resize.
    resize_width = None
    pending_kill = None
    is_collector = False
    try:
        tty.setcbreak(fd)
        # tmux's default MouseDown1Pane binding forwards clicks to applications
        # that request mouse input. SGR mode keeps coordinates unambiguous.
        sys.stdout.write("\x1b[?25l" + MOUSE_ENABLE)  # hide cursor
        sys.stdout.flush()

        rows = []
        next_poll = 0.0
        have_snapshot = False
        focused_pane = False
        sessions, current, counts = [], "", {"running": 0, "done": 0}
        focused_panes, visible_windows = set(), set()
        while True:
            now = time.time()
            if now >= next_poll:
                if not is_collector:
                    is_collector = try_claim_collector(lock_fd)
                if is_collector:
                    snapshot = collect()
                    sessions, current, counts, focused_panes, visible_windows = snapshot
                    have_snapshot = True
                    try:
                        publish_snapshot(snapshot)
                    except OSError:
                        # Keep rendering the live in-memory snapshot. Followers
                        # retain their last valid cache until publication works.
                        pass
                else:
                    snapshot = read_snapshot()
                    if snapshot is not None:
                        sessions, current, counts, focused_panes, visible_windows = snapshot
                        have_snapshot = True
                rows = build_rows(sessions)
                was_focused = focused_pane
                focused_pane = own_pane in focused_panes
                # Entering the sidebar should start the cursor on the current
                # session, not wherever it was left last time.
                if focused_pane and not was_focused:
                    idx = current_row_index(rows, current)
                    if idx is not None:
                        focus_idx = idx
                next_poll = now + cfg["tick_seconds"]

            resized[0] = False
            is_visible = not own_window or own_window in visible_windows
            if have_snapshot and not is_collector and not is_visible:
                if hibernate_renderer(own_pane, own_window, wake_read):
                    next_poll = 0.0
                    continue
                # The cache can lag a just-selected window by one collector
                # tick. Keep this renderer active instead of immediately
                # re-entering hibernation against the same stale snapshot.
                is_visible = True

            # Clamp focus to session rows only (group headers are labels).
            session_indices = [i for i, r in enumerate(rows) if r[0] == "session"]
            if session_indices and focus_idx not in session_indices:
                focus_idx = min(
                    session_indices,
                    key=lambda i: abs(i - focus_idx),
                )
            elif not session_indices:
                focus_idx = 0

            # A hidden collector still gathers and publishes state, but it does
            # not redraw a pane no client can see.
            if is_visible:
                frame = render(
                    rows,
                    current,
                    counts,
                    # Hide the › marker while the pane is unfocused - a persistent
                    # cursor row in every sidebar is noise when keys don't reach it.
                    focus_idx if focused_pane else None,
                    cfg,
                    terminal_width(cfg),
                    terminal_height(),
                    resize_width if resize_mode else None,
                    pending_kill,
                )
                sys.stdout.write(frame)
                sys.stdout.flush()

            key = read_key(max(0.05, next_poll - time.time()), wake_read)
            if key is None:
                continue
            # Any keypress implies the pane has focus; reflect it immediately
            # instead of waiting up to a full tick for the next poll. On this
            # transition, also snap the cursor to the current session so the
            # first key operates from there.
            if not focused_pane:
                focused_pane = True
                idx = current_row_index(rows, current)
                if idx is not None:
                    focus_idx = idx
            keys = cfg["keys"]

            if pending_kill is not None:
                response = key.lower() if isinstance(key, str) else key
                if response == "y":
                    kill_session(pending_kill)
                    pending_kill = None
                    next_poll = 0.0
                elif response in ("n", "escape"):
                    pending_kill = None
                continue

            if isinstance(key, tuple) and key[0] == "mouse-down":
                # Screen rows are one-based: two header lines place rows[0]
                # on terminal row 3. Labels and spacers intentionally ignore
                # clicks; every visible session row switches immediately.
                row_idx = key[2] - 3
                if 0 <= row_idx < len(rows):
                    row = rows[row_idx]
                    if row[0] == "session":
                        switch_session(row[1].name)
                continue

            # Resize mode: ←/→ nudge the pane width one column at a time and
            # persist it to @tmux_sidebar_width; any other key exits the mode.
            if resize_mode:
                if key == "left":
                    resize_width = max(10, resize_width - 1)
                    apply_width(own_pane, resize_width)
                elif key == "right":
                    resize_width += 1
                    apply_width(own_pane, resize_width)
                else:
                    resize_mode = False
                    set_repair_pause(False)
                continue

            if key == keys["quit"]:
                return 0
            if key == keys["resize"]:
                resize_mode = True
                resize_width = terminal_width(cfg)
                set_repair_pause(True)
            elif key == keys["kill"] and session_indices:
                row = rows[focus_idx]
                if row[0] == "session":
                    pending_kill = row[1].name
            elif key == keys["clear"]:
                # Reset the current (client-active) session's symbols when they
                # are wrong, then re-poll so the sidebar redraws immediately.
                clear_session_status(current)
                next_poll = 0.0
            elif key == keys["down"] and session_indices:
                later = [i for i in session_indices if i > focus_idx]
                focus_idx = later[0] if later else session_indices[0]
            elif key == keys["up"] and session_indices:
                earlier = [i for i in session_indices if i < focus_idx]
                focus_idx = earlier[-1] if earlier else session_indices[-1]
            elif key == keys["switch"] and session_indices:
                row = rows[focus_idx]
                if row[0] == "session":
                    switch_session(row[1].name)
    finally:
        # Never leave the repair gate closed if the sidebar dies mid-resize.
        if resize_mode:
            tmux("set", "-gu", "@tmux_sidebar_repair_pause")
        if own_pane:
            tmux("set-option", "-pu", "-t", own_pane, HIBERNATING_OPTION)
        os.close(lock_fd)
        os.close(wake_read)
        os.close(wake_write)
        termios.tcsetattr(fd, termios.TCSADRAIN, old_attrs)
        sys.stdout.write(MOUSE_DISABLE + "\x1b[?25h" + RESET)
        sys.stdout.flush()


if __name__ == "__main__":
    sys.exit(main() or 0)
