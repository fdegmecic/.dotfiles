//! claude-statusbar
//!
//! Three modes:
//!   claude-statusbar set <status>   read a Claude Code hook JSON on stdin, record this
//!                                   session's status to a per-session state file
//!   claude-statusbar end            read a hook JSON on stdin, drop this session's file
//!   claude-statusbar                 (no args) scan all sessions and print the widget
//!                                   JSON for a noctalia CustomButton: {text,icon,tooltip,color}
//!
//! Status values: idle | working | waiting | done

use std::env;
use std::fs;
use std::io::{Read, Write};
use std::path::PathBuf;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const STALE_DROP_SECS: u64 = 24 * 60 * 60; // forget sessions untouched for a day
const WORKING_DEMOTE_SECS: u64 = 10 * 60; // a "working" session this old likely died mid-run

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.first().map(|s| s.as_str()) {
        Some("set") => {
            let status = args.get(1).map(|s| s.as_str()).unwrap_or("idle");
            cmd_set(status);
        }
        Some("tool") => cmd_tool(),
        Some("end") => cmd_end(),
        Some("notify") => cmd_notify(),
        Some("attach") => cmd_attach(),
        Some("focus") => cmd_focus(args.get(1).map(|s| s.as_str())),
        Some("watch") => cmd_watch(),
        _ => print!("{}", render()),
    }
}

/// Run at SessionStart: find the niri window this session runs in by walking the
/// process tree and matching an ancestor pid to a window's client pid (the
/// terminal or IDE that launched `claude`). Store that pid — a stable key we
/// re-resolve to a live window id on click. Doesn't re-resolve if already set.
fn cmd_attach() {
    let input = read_stdin();
    let session = match extract_str(&input, "session_id") {
        Some(s) if !s.is_empty() => s,
        _ => return,
    };
    let existing = fs::read_to_string(state_dir().join(format!("{}.json", sanitize(&session))))
        .ok()
        .and_then(|c| extract_u64(&c, "winpid"))
        .unwrap_or(0);
    if existing > 0 {
        write_status(&input, "idle", None); // keep the pid we already matched
    } else {
        write_status(&input, "idle", Some(resolve_window_pid())); // (re)try the match
    }
}

/// Focus the niri window whose client pid matches `pid` (re-resolved live, so a
/// changed window id doesn't matter). Run on click from the panel.
fn cmd_focus(pid_arg: Option<&str>) {
    let pid: u64 = match pid_arg.and_then(|s| s.parse().ok()) {
        Some(p) => p,
        None => return,
    };
    if let Some((id, _)) = niri_windows().into_iter().find(|(_, p)| *p == pid) {
        let _ = std::process::Command::new("niri")
            .args(["msg", "action", "focus-window", "--id", &id.to_string()])
            .status();
    }
}

/// The terminal/IDE window pid for the current process: the first ancestor pid
/// that is also a niri window's client pid. Returns 0 if no match (e.g. over
/// SSH, or no compositor) — 0 is stored to mark "tried, none".
fn resolve_window_pid() -> u64 {
    let windows = niri_windows();
    if windows.is_empty() {
        return 0;
    }
    let win_pids: std::collections::HashSet<u64> = windows.iter().map(|(_, p)| *p).collect();
    ancestor_pids().into_iter().find(|p| win_pids.contains(p)).unwrap_or(0)
}

/// (window_id, client_pid) for every niri window.
fn niri_windows() -> Vec<(u64, u64)> {
    let out = match std::process::Command::new("niri")
        .args(["msg", "--json", "windows"])
        .output()
    {
        Ok(o) if o.status.success() => o,
        _ => return Vec::new(),
    };
    let json = String::from_utf8_lossy(&out.stdout);
    split_top_level_objects(&json)
        .iter()
        .filter_map(|obj| Some((extract_u64(obj, "id")?, extract_u64(obj, "pid")?)))
        .collect()
}

/// Walk /proc to collect this process's ancestor pids (self first, up to init).
fn ancestor_pids() -> Vec<u64> {
    let mut pids = Vec::new();
    let mut pid = std::process::id() as u64;
    for _ in 0..64 {
        if pid <= 1 {
            break;
        }
        pids.push(pid);
        match read_ppid(pid) {
            Some(ppid) if ppid != pid => pid = ppid,
            _ => break,
        }
    }
    pids
}

fn read_ppid(pid: u64) -> Option<u64> {
    // /proc/<pid>/stat: "pid (comm) state ppid ...". comm may contain spaces and
    // parens, so split after the LAST ')'.
    let s = fs::read_to_string(format!("/proc/{}/stat", pid)).ok()?;
    let after = &s[s.rfind(')')? + 1..];
    let mut fields = after.split_whitespace();
    let _state = fields.next()?;
    fields.next()?.parse().ok()
}

/// Split a JSON array into its top-level `{...}` object substrings, respecting
/// strings/escapes (window titles can contain braces and quotes).
fn split_top_level_objects(s: &str) -> Vec<String> {
    let bytes = s.as_bytes();
    let mut objs = Vec::new();
    let mut depth = 0i32;
    let mut start = 0usize;
    let mut in_str = false;
    let mut esc = false;
    for i in 0..bytes.len() {
        let c = bytes[i];
        if in_str {
            if esc {
                esc = false;
            } else if c == b'\\' {
                esc = true;
            } else if c == b'"' {
                in_str = false;
            }
            continue;
        }
        match c {
            b'"' => in_str = true,
            b'{' => {
                if depth == 0 {
                    start = i;
                }
                depth += 1;
            }
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    objs.push(s[start..=i].to_string());
                }
            }
            _ => {}
        }
    }
    objs
}

/// The Notification hook fires both for permission prompts AND for the idle
/// "Claude is waiting for your input" nudge ~60s after a session finishes.
/// Only the former should raise the red "needs you" state; the latter is just
/// a finished session awaiting a prompt, i.e. "done".
fn cmd_notify() {
    let input = read_stdin();
    let msg = extract_str(&input, "message").unwrap_or_default().to_lowercase();
    let status = if msg.contains("permission") || msg.contains("approve") || msg.contains("confirm") {
        "waiting"
    } else {
        "done"
    };
    write_status(&input, status, None);
}

/// Long-lived mode for the CustomButton `textStream` widget: emit a JSON line
/// only when the rendered state actually changes, so the bar updates the instant
/// a session flips state instead of waiting for the next poll.
fn cmd_watch() {
    let mut last = String::new();
    loop {
        let cur = render();
        if cur != last {
            println!("{}", cur);
            let _ = std::io::stdout().flush();
            last = cur;
        }
        std::thread::sleep(Duration::from_millis(200));
    }
}

fn state_dir() -> PathBuf {
    let base = env::var("XDG_STATE_HOME")
        .ok()
        .filter(|s| !s.is_empty())
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            let home = env::var("HOME").unwrap_or_default();
            PathBuf::from(home).join(".local/state")
        });
    base.join("claude-statusbar")
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn read_stdin() -> String {
    let mut buf = String::new();
    let _ = std::io::stdin().read_to_string(&mut buf);
    buf
}

fn cmd_set(status: &str) {
    let input = read_stdin();
    write_status(&input, status, None);
}

/// PreToolUse: working state with a human label for the tool being used.
fn cmd_tool() {
    let input = read_stdin();
    let label = tool_label(&extract_str(&input, "tool_name").unwrap_or_default());
    persist(&input, "working", &label, None);
}

/// Friendly description of what a tool call is doing.
fn tool_label(tool: &str) -> String {
    match tool {
        "Edit" | "Write" | "MultiEdit" | "NotebookEdit" => "Editing",
        "Read" => "Reading",
        "Bash" | "BashOutput" | "KillShell" => "Running command",
        "Grep" | "Glob" => "Searching",
        "WebFetch" | "WebSearch" => "Searching the web",
        "Task" => "Running a subagent",
        "TodoWrite" => "Planning",
        "" => "Working",
        other if other.starts_with("mcp__") => "Using a tool",
        other => other,
    }
    .to_string()
}

fn write_status(input: &str, status: &str, winpid_override: Option<u64>) {
    persist(input, status, "", winpid_override);
}

/// Write a session's state file.
/// `winpid_override`: Some(pid) = store this pid (0 = "tried, no window");
/// None = keep the file's pid if it has one, otherwise resolve it once now (so
/// any hook, not just SessionStart, backfills the window match).
/// `detail`: short label of the current action; empty clears it.
fn persist(input: &str, status: &str, detail: &str, winpid_override: Option<u64>) {
    let session = match extract_str(input, "session_id") {
        Some(s) if !s.is_empty() => s,
        _ => return, // nothing we can key on; do nothing
    };
    let cwd = extract_str(input, "cwd").unwrap_or_default();
    let now = now();

    let dir = state_dir();
    let _ = fs::create_dir_all(&dir);
    let path = dir.join(format!("{}.json", sanitize(&session)));
    let existing = fs::read_to_string(&path).ok();

    let winpid = match winpid_override {
        Some(w) => w,
        None => existing
            .as_deref()
            .and_then(|c| extract_u64(c, "winpid")) // known (or tried -> 0)
            .unwrap_or_else(resolve_window_pid),
    };

    // Session name = Claude's generated title (from the transcript), refreshed at
    // most every 15s so frequent hooks don't re-scan the transcript file.
    let prev_title = existing.as_deref().and_then(|c| extract_str(c, "title")).unwrap_or_default();
    let prev_tts = existing.as_deref().and_then(|c| extract_u64(c, "tts")).unwrap_or(0);
    let (title, tts) = if !prev_title.is_empty() && now.saturating_sub(prev_tts) < 15 {
        (prev_title, prev_tts)
    } else {
        let tpath = extract_str(input, "transcript_path").unwrap_or_default();
        match read_title(&tpath) {
            Some(t) => (t, now),
            None => (prev_title, now), // keep old; stamp now to throttle retries
        }
    };

    let title_field = if title.is_empty() {
        String::new()
    } else {
        format!(",\"title\":\"{}\"", json_escape(&title))
    };
    let detail_field = if detail.is_empty() {
        String::new()
    } else {
        format!(",\"detail\":\"{}\"", json_escape(detail))
    };

    let body = format!(
        "{{\"status\":\"{}\",\"cwd\":\"{}\",\"ts\":{},\"winpid\":{},\"tts\":{}{}{}}}",
        json_escape(status),
        json_escape(&cwd),
        now,
        winpid,
        tts,
        title_field,
        detail_field
    );
    let _ = fs::write(path, body);
}

/// The session's display name from the transcript: a user `/rename`
/// (`customTitle`) wins over Claude's generated `aiTitle`.
fn read_title(transcript_path: &str) -> Option<String> {
    if transcript_path.is_empty() {
        return None;
    }
    let s = fs::read_to_string(transcript_path).ok()?;
    for key in ["customTitle", "aiTitle"] {
        let pat = format!("\"{}\"", key);
        if let Some(idx) = s.rfind(&pat) {
            // last occurrence = most recent
            if let Some(t) = extract_str(&s[idx..], key).filter(|t| !t.is_empty()) {
                return Some(t);
            }
        }
    }
    None
}

fn cmd_end() {
    let input = read_stdin();
    if let Some(session) = extract_str(&input, "session_id") {
        if !session.is_empty() {
            let _ = fs::remove_file(state_dir().join(format!("{}.json", sanitize(&session))));
        }
    }
}

struct Session {
    status: String,
    cwd: String,
    ts: u64,
    age: u64,
    winpid: u64,
    detail: String,
    title: String,
}

/// Is `pid` a live process?
fn proc_alive(pid: u64) -> bool {
    pid > 0 && std::path::Path::new(&format!("/proc/{}", pid)).exists()
}

fn render() -> String {
    let dir = state_dir();
    let now = now();
    let mut sessions: Vec<Session> = Vec::new();

    if let Ok(entries) = fs::read_dir(&dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) != Some("json") {
                continue;
            }
            let content = match fs::read_to_string(&path) {
                Ok(c) => c,
                Err(_) => continue,
            };
            let ts = extract_u64(&content, "ts").unwrap_or(0);
            let age = now.saturating_sub(ts);
            let winpid = extract_u64(&content, "winpid").unwrap_or(0);

            // Prune dead sessions: terminal/IDE window gone, or untouched for a day.
            if (winpid > 0 && !proc_alive(winpid)) || age > STALE_DROP_SECS {
                let _ = fs::remove_file(&path);
                continue;
            }

            let mut status = extract_str(&content, "status").unwrap_or_else(|| "idle".into());
            let mut detail = extract_str(&content, "detail").unwrap_or_default();
            if status == "working" && age > WORKING_DEMOTE_SECS {
                status = "done".into(); // missed Stop hook / crashed; stop spinning forever
                detail.clear();
            }
            let cwd = extract_str(&content, "cwd").unwrap_or_default();
            let title = extract_str(&content, "title").unwrap_or_default();
            sessions.push(Session { status, cwd, ts, age, winpid, detail, title });
        }
    }

    let total = sessions.len();
    if total == 0 {
        return "{\"text\":\"\",\"label\":\"\",\"icon\":\"robot\",\"color\":\"secondary\",\"tooltip\":\"No active Claude sessions\",\"sessions\":[]}".to_string();
    }

    // Headline = the most attention-worthy state across all sessions.
    let headline = sessions
        .iter()
        .map(|s| s.status.as_str())
        .max_by_key(|s| priority(s))
        .unwrap_or("idle");
    let (icon, color) = appearance(headline);
    let headline_count = sessions.iter().filter(|s| s.status == headline).count();
    let summary = state_summary(headline, headline_count);

    // Pill text: show the count only when more than one session is live.
    let text = if total >= 2 {
        total.to_string()
    } else {
        String::new()
    };

    // Tooltip: one line per session, most-urgent first.
    let mut lines: Vec<&Session> = sessions.iter().collect();
    lines.sort_by(|a, b| {
        priority(&b.status)
            .cmp(&priority(&a.status))
            .then(a.age.cmp(&b.age))
    });
    let header = format!("Claude — {} session{}", total, if total == 1 { "" } else { "s" });
    let mut tip = String::from(&header);
    let mut sess_json: Vec<String> = Vec::new();
    for s in lines {
        // Prefer Claude's session title; fall back to the working-directory name.
        let name = if s.title.is_empty() {
            basename(&s.cwd)
        } else {
            s.title.clone()
        };
        // While working, prefer the action detail ("Editing") over the generic label.
        let state_label = if s.status == "working" && !s.detail.is_empty() {
            s.detail.as_str()
        } else {
            label(&s.status)
        };
        tip.push('\n');
        tip.push_str(&format!(
            "{} {} — {} ({})",
            bullet(&s.status),
            name,
            state_label,
            human_age(s.age)
        ));
        let (sicon, scolor) = appearance(&s.status);
        sess_json.push(format!(
            "{{\"name\":\"{}\",\"dir\":\"{}\",\"status\":\"{}\",\"detail\":\"{}\",\"ts\":{},\"age\":{},\"ageText\":\"{}\",\"icon\":\"{}\",\"color\":\"{}\",\"winpid\":{}}}",
            json_escape(&name),
            json_escape(&s.cwd),
            json_escape(&s.status),
            json_escape(&s.detail),
            s.ts,
            s.age,
            human_age(s.age),
            sicon,
            scolor,
            s.winpid
        ));
    }

    format!(
        "{{\"text\":\"{}\",\"label\":\"{}\",\"icon\":\"{}\",\"color\":\"{}\",\"tooltip\":\"{}\",\"sessions\":[{}]}}",
        json_escape(&text),
        json_escape(&summary),
        icon,
        color,
        json_escape(&tip),
        sess_json.join(",")
    )
}

/// Short, self-explanatory bar label: "3 working", "1 needs you", "2 done".
fn state_summary(status: &str, n: usize) -> String {
    match status {
        "waiting" => {
            if n == 1 {
                "1 needs you".to_string()
            } else {
                format!("{} need you", n)
            }
        }
        "compacting" => format!("{} compacting", n),
        "working" => format!("{} working", n),
        "done" => format!("{} done", n),
        _ => format!("{} idle", n),
    }
}

fn priority(status: &str) -> u8 {
    match status {
        "waiting" => 4,
        "compacting" => 3,
        "working" => 2,
        "done" => 1,
        _ => 0, // idle / unknown
    }
}

fn appearance(status: &str) -> (&'static str, &'static str) {
    match status {
        "waiting" => ("bell-ringing", "error"),
        "compacting" => ("refresh", "tertiary"),
        "working" => ("loader", "primary"),
        "done" => ("circle-check", "tertiary"),
        _ => ("robot", "secondary"),
    }
}

fn bullet(status: &str) -> &'static str {
    match status {
        "waiting" => "\u{25CF}",    // ●
        "compacting" => "\u{21BB}", // ↻
        "working" => "\u{25D0}",    // ◐
        "done" => "\u{2714}",       // ✔
        _ => "\u{25CB}",            // ○
    }
}

fn label(status: &str) -> &'static str {
    match status {
        "waiting" => "needs you",
        "compacting" => "compacting",
        "working" => "working",
        "done" => "done",
        _ => "idle",
    }
}

fn human_age(secs: u64) -> String {
    if secs < 60 {
        format!("{}s", secs)
    } else if secs < 3600 {
        format!("{}m", secs / 60)
    } else {
        format!("{}h", secs / 3600)
    }
}

fn basename(path: &str) -> String {
    let trimmed = path.trim_end_matches('/');
    if trimmed.is_empty() {
        return "~".into();
    }
    trimmed
        .rsplit('/')
        .next()
        .filter(|s| !s.is_empty())
        .unwrap_or(trimmed)
        .to_string()
}

/// Filename-safe session id (uuids are already safe; guard against surprises).
fn sanitize(s: &str) -> String {
    s.chars()
        .map(|c| if c.is_ascii_alphanumeric() || c == '-' || c == '_' { c } else { '_' })
        .collect()
}

fn json_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out
}

/// Pull a top-level JSON string value by key, with minimal escape handling.
/// Good enough for the well-formed JSON emitted by Claude Code hooks and our own files.
fn extract_str(input: &str, key: &str) -> Option<String> {
    let pat = format!("\"{}\"", key);
    let bytes = input.as_bytes();
    let mut from = 0usize;
    while let Some(rel) = input[from..].find(&pat) {
        let mut i = from + rel + pat.len();
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() || bytes[i] != b':' {
            from = from + rel + pat.len();
            continue;
        }
        i += 1;
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() || bytes[i] != b'"' {
            from = from + rel + pat.len();
            continue;
        }
        i += 1;
        let mut out: Vec<u8> = Vec::new();
        while i < bytes.len() {
            let c = bytes[i];
            if c == b'\\' && i + 1 < bytes.len() {
                match bytes[i + 1] {
                    b'"' => out.push(b'"'),
                    b'\\' => out.push(b'\\'),
                    b'/' => out.push(b'/'),
                    b'n' => out.push(b'\n'),
                    b't' => out.push(b'\t'),
                    b'r' => out.push(b'\r'),
                    other => {
                        out.push(b'\\');
                        out.push(other);
                    }
                }
                i += 2;
                continue;
            }
            if c == b'"' {
                return Some(String::from_utf8_lossy(&out).into_owned());
            }
            out.push(c);
            i += 1;
        }
        return Some(String::from_utf8_lossy(&out).into_owned());
    }
    None
}

/// Pull a top-level JSON integer value by key.
fn extract_u64(input: &str, key: &str) -> Option<u64> {
    let pat = format!("\"{}\"", key);
    let bytes = input.as_bytes();
    let rel = input.find(&pat)?;
    let mut i = rel + pat.len();
    while i < bytes.len() && bytes[i].is_ascii_whitespace() {
        i += 1;
    }
    if i >= bytes.len() || bytes[i] != b':' {
        return None;
    }
    i += 1;
    while i < bytes.len() && bytes[i].is_ascii_whitespace() {
        i += 1;
    }
    let start = i;
    while i < bytes.len() && bytes[i].is_ascii_digit() {
        i += 1;
    }
    if i == start {
        return None;
    }
    input[start..i].parse().ok()
}
