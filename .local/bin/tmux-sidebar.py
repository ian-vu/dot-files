#!/usr/bin/env python3
"""tmux-sidebar: minimal always-visible tmux session list with Pi agent status.

One instance runs per tmux window (spawned by sidebar-ensure.sh). Every tick
(~1s) it rebuilds session state by polling tmux and reading the status files
Pi's tmux-notify extension writes to /tmp/tmux-sidebar/<pane_id>.json, so all
instances render identical state without any coordination. Only the keyboard
focus row is per-instance.

Status protocol (see .ignore/reports/tmux-sidebar-spec.md):
  - state "running" / "waiting" / "done"; idle is the absence of a file.
  - "running"/"waiting" files whose pid is dead are reaped (crash cleanup);
    "done" files outlive the process by design and are cleared by
    clear-bell.sh when the pane is focused.

Python 3 stdlib only: subprocess polling, raw-terminal input, ANSI redraws.
"""

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

STATUS_DIR = "/tmp/tmux-sidebar"
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
        "refresh": "r",
        "resize": "w",
        "quit": "q",
    },
    "tick_seconds": 1.0,
    "stale_hours": 5,
    "elapsed_alert_minutes": 10,
}

# Aggregation priority: a blocked agent (waiting) outranks a working one.
STATE_PRIORITY = {"waiting": 3, "running": 2, "done": 1, "idle": 0}
GLYPHS = {"waiting": "❗", "running": "⚡", "done": "✓", "idle": "○"}
# ⚡ and ❗ are East-Asian-Wide (2 terminal cells); ✓ and ○ are 1. Pad the
# narrow ones so the glyph column is always 2 cells and names never shift
# when a session's state changes.
GLYPH_PAD = {"waiting": "", "running": "", "done": " ", "idle": " "}

# ANSI styles (plain codes; no curses dependency).
RESET = "\x1b[0m"
DIM = "\x1b[2m"
BOLD = "\x1b[1m"
RED = "\x1b[31m"
GREEN = "\x1b[32m"
YELLOW = "\x1b[33m"
CYAN = "\x1b[36m"
EXTRA_DIM = "\x1b[2;90m"


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


def pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except (PermissionError, OSError, TypeError, ValueError):
        # Permission errors mean the pid exists but belongs to another user.
        return True


def read_status_files():
    """Read all status files; reap running/waiting files with dead pids.

    Returns {session_name: [entry, ...]}. Session names are re-resolved from
    the live pane when possible so renamed sessions stay correct.
    """
    entries = []
    try:
        names = os.listdir(STATUS_DIR)
    except OSError:
        return {}

    for name in names:
        if not name.endswith(".json"):
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

    # Re-resolve session names from live panes in one tmux call so renamed
    # sessions attribute their status files correctly.
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


def list_sessions():
    """[(name, attached_count)] in tmux natural order."""
    out = tmux("list-sessions", "-F", "#{session_name}" + SEP + "#{session_attached}")
    if not out:
        return []
    sessions = []
    for line in out.splitlines():
        name, _, attached = line.partition(SEP)
        try:
            sessions.append((name, int(attached)))
        except ValueError:
            sessions.append((name, 0))
    return sessions


def session_panes_info(session):
    """(first_pane_cwd, max_pane_activity) for a session, single tmux call."""
    out = tmux(
        "list-panes",
        "-s",
        "-t",
        session,
        "-F",
        "#{pane_current_path}" + SEP + "#{pane_activity}",
    )
    cwd = None
    activity = 0
    if out:
        for line in out.splitlines():
            path, _, act = line.partition(SEP)
            if cwd is None and path:
                cwd = path
            try:
                activity = max(activity, int(act))
            except ValueError:
                pass
    return cwd, activity


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
        "stale",
    )

    def __init__(self, name):
        self.name = name
        self.state = "idle"
        self.state_ts = 0
        self.cwd = None
        self.group = None
        self.is_worktree = False
        self.stale = False


def pane_focused(own_pane):
    """True when this sidebar pane is the pane the attached client is on -
    i.e. keys typed by the user actually reach the sidebar. Drives whether
    the › focus marker renders at all.

    Compare against the client's current pane, not this pane's
    pane_active/window_active flags: those are per-session state, so a
    sidebar left focused in a background session would keep claiming focus
    while the client is viewing another session."""
    if not own_pane:
        return False
    # list-clients, not display-message: an untargeted display-message from
    # this process defaults to TMUX_PANE (this very pane), which would always
    # report focused.
    out = tmux("list-clients", "-F", "#{pane_id}")
    if not out:
        return False
    return own_pane in out.split()


def collect(cfg):
    """One poll tick: build the full session model.

    Returns (sessions, current_session, counts) where counts is
    {running, done} for the header.
    """
    now = time.time()
    status = read_status_files()
    sessions = []
    for name, _attached in list_sessions():
        sess = Session(name)
        files = status.get(name, [])
        if files:
            best = max(files, key=lambda f: STATE_PRIORITY.get(f.get("state"), 0))
            sess.state = best.get("state", "idle")
            sess.state_ts = best.get("ts", 0) or 0
        cwd, activity = session_panes_info(name)
        sess.cwd = cwd
        sess.group, sess.is_worktree = repo_info(cwd)
        # Sessions with an active status file are never dimmed.
        sess.stale = (
            sess.state == "idle"
            and activity > 0
            and now - activity > cfg["stale_hours"] * 3600
        )
        sessions.append(sess)

    # list-clients, not an untargeted display-message: the latter resolves
    # against TMUX_PANE (this sidebar's own session), not the attached client,
    # so the ▌ current marker would stick to whatever session hosts the pane.
    current = (tmux("list-clients", "-F", "#{session_name}") or "").strip()
    current = current.splitlines()[0] if current else ""
    counts = {
        "running": sum(1 for s in sessions if s.state in ("running", "waiting")),
        "done": sum(1 for s in sessions if s.state == "done"),
    }
    return sessions, current, counts


def build_rows(sessions):
    """Flatten sessions into render rows, grouping a repo's main checkout
    with its worktree sessions.

    Row: (kind, session_or_None, label, rail) where kind is "session",
    "group", or "spacer" (blank gap line between every row; inside a group
    the spacer carries the │ rail so the group still reads connected). A group
    renders only when >=2 sessions share a repo root AND at least one is a
    linked worktree - two plain sessions that happen to sit in the same repo
    stay separate rows. Inside a group, the repo's own session - the
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
        grouped = (
            members
            and len(members) >= 2
            and any(m.is_worktree for m in members)
        )
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
                    # Home symbol for the repo's main checkout, suffixed with
                    # "home" so the root row is labeled, not just a glyph.
                    label = "⌂ home"
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


def visible_len(text):
    """Length ignoring ANSI escapes (glyphs assumed single-cell)."""
    return len(re.sub(r"\x1b\[[0-9;]*m", "", text))


def truncate(name, limit):
    if limit <= 0:
        return ""
    if len(name) <= limit:
        return name
    return name[: max(0, limit - 1)] + "…"


def render(rows, current, counts, focus_idx, cfg, width, height, resize_width):
    """resize_width is the in-progress resize target, or None outside
    resize mode (it drives the footer's width indicator). focus_idx is None
    when the sidebar pane itself is not focused: the › marker only makes
    sense while keys actually reach this pane."""
    resize_mode = resize_width is not None
    alert_secs = cfg["elapsed_alert_minutes"] * 60
    now = time.time()
    lines = []

    # Header: title + running / unseen-done counts, right-aligned.
    right = ""
    if counts["running"]:
        right += f"⚡{counts['running']}"
    if counts["done"]:
        right += ("  " if right else "") + f"✓{counts['done']}"
    title = " sessions"
    pad = max(1, width - len(title) - visible_len(right) - 1)
    lines.append(f"{DIM}{title}{RESET}{' ' * pad}{YELLOW}{right}{RESET}")
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
            glyph = GLYPHS[agg] + GLYPH_PAD[agg]
            name = truncate(label, width - 6)
            lines.append(f"  {DIM}{glyph} {name}{RESET}")
            continue

        marker = "▌" if sess.name == current else ("›" if focused else " ")
        glyph = GLYPHS[sess.state] + GLYPH_PAD[sess.state]
        glyph_style = {
            "waiting": RED + BOLD,
            "running": YELLOW,
            "done": GREEN + BOLD,
            "idle": DIM,
        }[sess.state]

        suffix = ""
        suffix_style = DIM
        if sess.state in ("running", "waiting") and sess.state_ts:
            elapsed = now - sess.state_ts
            suffix = format_elapsed(elapsed)
            # An agent running/blocked past the alert threshold is stuck or
            # forgotten; make it loud.
            suffix_style = RED + BOLD if elapsed >= alert_secs else DIM

        indent = f"{DIM}{rail}{RESET} " if rail else ""
        # Columns: [marker 1][space][glyph 2][space][name] fixed so rows never shift.
        prefix_cells = 2 + (2 if rail else 0) + 3  # marker+space (+rail+space) +glyph+space
        name_limit = width - prefix_cells - (len(suffix) + 1 if suffix else 0) - 1
        # label, not sess.name: grouped main checkouts display as "root".
        name = truncate(label, name_limit)

        # No background highlight (reverse video reads as a grey bar that
        # fights the theme's transparent background); the current session and
        # the ›-selected row get a bold bright name instead.
        name_style = ""
        if sess.stale:
            name_style = EXTRA_DIM
        elif sess.name == current or focused:
            name_style = BOLD
        elif sess.state == "idle":
            name_style = DIM

        line = (
            f"{CYAN}{marker}{RESET} {indent}{glyph_style}{glyph}{RESET} "
            f"{name_style}{name}{RESET}"
        )
        if suffix:
            line += f" {suffix_style}{suffix}{RESET}"
        lines.append(line)

    # Footer pinned to the bottom. In resize mode it becomes a small inline
    # width indicator instead of a popup: ←/→ nudge one column at a time.
    keys = cfg["keys"]
    footer_rule = f"{DIM}{'─' * max(0, width - 2)}{RESET}"
    if resize_mode:
        footer = (
            f" {BOLD}{YELLOW}width {resize_width}{RESET}"
            f"{DIM}  ←/→ adjust  ⏎ done{RESET}"
        )
    else:
        footer = (
            f"{DIM} ⏎ go  {keys['down']}/{keys['up']} move  "
            f"{keys['resize']} width  {keys['quit']} quit{RESET}"
        )
    while len(lines) < height - 2:
        lines.append("")
    lines = lines[: height - 2]
    lines.append(f" {footer_rule}")
    lines.append(footer)

    # Home, then each line followed by clear-to-eol. No newline after the last
    # line: writing past the bottom row would scroll the frame up by one.
    body = "\x1b[K\r\n".join(lines)
    return f"\x1b[H{body}\x1b[K\x1b[J"


# Pending input bytes. Multiple keys can queue while a slow poll tick runs;
# reading them in one os.read and returning only the first would drop or
# mangle the rest, so parsing pops exactly one key per call from this buffer.
_input_buffer = b""


def _pop_key():
    """Pop one normalized key from the buffer, or None if incomplete."""
    global _input_buffer
    if not _input_buffer:
        return None
    if _input_buffer[:1] == b"\x1b":
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


def read_key(timeout):
    """Return one normalized key within timeout, or None on tick timeout."""
    global _input_buffer
    key = _pop_key()
    if key is not None:
        return key
    ready, _, _ = select.select([sys.stdin], [], [], timeout)
    if not ready:
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
    if own_pane:
        tmux("select-pane", "-t", own_pane, "-T", "tmux-sidebar")

    if not sys.stdin.isatty():
        print("tmux-sidebar must run inside a tmux pane", file=sys.stderr)
        return 1

    fd = sys.stdin.fileno()
    old_attrs = termios.tcgetattr(fd)
    resized = [True]

    def on_resize(_sig, _frame):
        resized[0] = True

    signal.signal(signal.SIGWINCH, on_resize)

    focus_idx = 0
    resize_mode = False
    # Target width during resize mode. Tracked locally because the pane's
    # observed terminal size lags resize-pane by a frame; reading it back per
    # keypress would make rapid ←/→ presses fight the previous resize.
    resize_width = None
    try:
        tty.setcbreak(fd)
        sys.stdout.write("\x1b[?25l")  # hide cursor
        sys.stdout.flush()

        rows = []
        next_poll = 0.0
        focused_pane = False
        sessions, current, counts = [], "", {"running": 0, "done": 0}
        while True:
            now = time.time()
            if now >= next_poll or resized[0]:
                resized[0] = False
                sessions, current, counts = collect(cfg)
                rows = build_rows(sessions)
                focused_pane = pane_focused(own_pane)
                next_poll = now + cfg["tick_seconds"]

            # Clamp focus to session rows only (group headers are labels).
            session_indices = [i for i, r in enumerate(rows) if r[0] == "session"]
            if session_indices and focus_idx not in session_indices:
                focus_idx = min(
                    session_indices,
                    key=lambda i: abs(i - focus_idx),
                )
            elif not session_indices:
                focus_idx = 0

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
            )
            sys.stdout.write(frame)
            sys.stdout.flush()

            key = read_key(max(0.05, next_poll - time.time()))
            if key is None:
                continue
            # Any keypress implies the pane has focus; reflect it immediately
            # instead of waiting up to a full tick for the next poll.
            focused_pane = True
            keys = cfg["keys"]

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
            elif key == keys["refresh"]:
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
                    tmux("switch-client", "-t", row[1].name)
    finally:
        # Never leave the repair gate closed if the sidebar dies mid-resize.
        if resize_mode:
            tmux("set", "-gu", "@tmux_sidebar_repair_pause")
        termios.tcsetattr(fd, termios.TCSADRAIN, old_attrs)
        sys.stdout.write("\x1b[?25h" + RESET)
        sys.stdout.flush()


if __name__ == "__main__":
    sys.exit(main() or 0)
