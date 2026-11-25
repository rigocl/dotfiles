#!/usr/bin/env python3
"""UserPromptSubmit: warn when a long session gets a prompt that looks like a
new task, and suggest a fresh session. Warn only, never block.

WHY: every call re-reads the whole conversation. The 2026-11-03 desktop usage
study found the median Opus call carries 155k tokens, often context left over
from earlier, unrelated work. A fresh session starts
near zero.

How it decides:
- context size = input + cache-read + cache-creation tokens of the last
  main-thread assistant message in the transcript; below LIMIT it stays quiet;
- "new task" = an explicit phrase ("new task", "unrelated", "switching to"),
  or a prompt of MIN_WORDS or more that does not open like a follow-up and
  shares under OVERLAP of its content words with the recent conversation;
- it fires at most once per REARM tokens of growth in a session.
A false positive costs one line of text; a miss costs nothing new.
"""
import json
import os
import pathlib
import re
import sys

LIMIT, REARM, MIN_WORDS, OVERLAP = 100_000, 50_000, 8, 0.2
TAIL_BYTES = 3_000_000

STOP = set("""about above after again also because been before being below between both
could does doing done down during each from further have having here into itself just
more most much must only other over same should some such than that their them then
there these they this those through under until very what when where which while will
with would your yours make want need like please thanks something anything everything
look check file files time today""".split())
FOLLOW = re.compile(r"^\s*(yes|yeah|yep|ok|okay|sure|go|do it|continue|also|and|then|that|this|it|"
                    r"those|these|same|again|thanks|thank you|perfect|great|good|nice|no|nope|wait|but|"
                    r"why|how come|what about|instead|actually|fix|apply|commit|push|ship|retry|try)\b", re.I)
EXPLICIT = re.compile(r"\b(new task|unrelated|different (topic|thing|task)|switching (to|gears)|"
                      r"separate(ly)? (question|task|thing)|change of topic|another thing)\b", re.I)


def words(text):
    return {w for w in re.findall(r"[a-z][a-z0-9_-]{3,}", text.lower()) if w not in STOP}


def text_of(content):
    if isinstance(content, str):
        return content
    out = []
    for c in content or []:
        if isinstance(c, dict) and c.get("type") == "text":
            out.append(c.get("text", ""))
    return " ".join(out)


try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
prompt = d.get("prompt") or ""
path = d.get("transcript_path") or ""
if not prompt or not path or not os.path.exists(path) or prompt.lstrip()[:1] in ("/", "<"):
    sys.exit(0)

with open(path, "rb") as fh:
    fh.seek(0, 2)
    fh.seek(max(0, fh.tell() - TAIL_BYTES))
    lines = fh.read().decode("utf-8", "replace").splitlines()

ctx, recent = 0, []
for line in lines:
    try:
        e = json.loads(line)
    except Exception:
        continue
    if e.get("isSidechain"):
        continue
    m = e.get("message") or {}
    if e.get("type") == "assistant" and m.get("usage"):
        u = m["usage"]
        ctx = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
               + u.get("cache_creation_input_tokens", 0))
    if e.get("type") in ("user", "assistant"):
        t = text_of(m.get("content"))
        if t:
            recent.append(t)
if ctx < LIMIT:
    sys.exit(0)

state = pathlib.Path(os.environ.get("TMPDIR") or "/tmp") / "claude-verify" / d.get("session_id", "none")
state.mkdir(parents=True, exist_ok=True)
f = state / "task_switch"
last = json.loads(f.read_text()).get("ctx", 0) if f.exists() else 0
if last and ctx < last + REARM:
    sys.exit(0)

new = bool(EXPLICIT.search(prompt))
if not new:
    pw = words(prompt)
    if len(prompt.split()) >= MIN_WORDS and not FOLLOW.match(prompt) and pw:
        seen = words(" ".join(recent[-30:]))
        new = len(pw & seen) / len(pw) < OVERLAP
if not new:
    sys.exit(0)

f.write_text(json.dumps({"ctx": ctx}))
k = round(ctx / 1000)
user_msg = (f"Context is {k}k tokens and this looks like a new task. "
            f"A fresh session would start near zero.")
model_msg = (f"Hook note: the conversation is at {k}k tokens and this prompt looks unrelated to the "
             f"recent work. Before starting, tell Rigo in one line that a fresh session "
             f"would be cheaper and faster, then carry on unless Rigo says otherwise.")
print(json.dumps({"systemMessage": user_msg,
                  "hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": model_msg}}))
