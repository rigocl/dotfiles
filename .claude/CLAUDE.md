@RTK.md

# Privileged (sudo) commands

I do not have passwordless sudo. When a task needs root/sudo (e.g.
`systemctl restart docker`, editing files under `/etc`, package installs),
do NOT attempt it silently or skip the step. Surface it and hand the exact
command to the user to run, then continue once they confirm. Prefer the
narrowest command that unblocks the task.

# Writing guidelines

Source of truth: `~/.claude/output-styles/rigo.md`, the `rigo` output style
(set globally by `outputStyle` in `~/.claude/settings.json`). Imported here
as well so the rules still load if a different output style is ever active.

@output-styles/rigo.md

# Topic memory

@projects/-home-rigo/memory/rigo-profile.md
@projects/-home-rigo/memory/ALWAYS.md

Memory is split by project. The table in ALWAYS.md above says where each
project's memory lives. Write a memory to the directory of the project it
is about, even when this session runs elsewhere. Use the `~` memory
(`~/.claude/projects/-home-rigo/memory/`) only for rules that apply
everywhere and for topics with no project of their own. A project marked
"in the ~ memory" keeps its files there until it moves.

Each directory holds one file per topic (kebab-case), frontmatter with
`name`, `title` (display name), `description` (the index hook, as a
breadcrumb: one "read when ..." line of about 100 characters naming the
situations, repos, hosts and commands in which a session needs the file;
no state: progress, dates and pending items live in the body and
review-by lines),
`metadata.type` (user | feedback | project | reference) and
`metadata.section` (broad-topic index heading). `MEMORY.md` in each is the
INDEX and a BUILD ARTIFACT, and so is `ALWAYS.md`: `regen-index.py` in the
`~` memory generates them from those frontmatter fields, review-by lines
and `scopes.json` — NEVER edit them by hand. Two hooks keep them true:
SessionStart regenerates them before injection (covers deletes/archives,
bash moves, and edits made outside Claude), and PostToolUse on Write|Edit
keeps them fresh mid-session. If one ever seems stale, run
`python3 ~/.claude/projects/-home-rigo/memory/regen-index.py`.
Deleting/archiving a memory = removing/moving the file; the index follows
at next regen. A new project goes in `scopes.json`.

Recall: the index is already in context — when a conversation touches a
topic, read the full file(s) behind the matching hooks; follow [[links]],
multiple topics can apply. If unsure which topic is meant, ask. Only the
launch folder's index is injected. For another project, or in a subfolder
of one, read that project's `MEMORY.md` first, using the table in
ALWAYS.md. Link names are unique, so find a `[[name]]` target with
`ls ~/.claude/projects/*/memory/<name>.md`.

Re-anchor: when Rigo is about to do real work on a project whose home in
the ALWAYS.md table differs from this session's folder, offer once, before
any tool call on that work and as the whole reply: "You're in X, but this
is about Y (folder). Want to move there?" This applies in `~` too, which is
a home for its own topics and not a place to work on projects. Do not offer for a
passing mention or a quick factual question; answer those in place by reading
that project's memory. If he declines, stay and do not ask again about that
topic in this session. If he accepts: run `hw ls` and resume a matching record
if there is one; otherwise start one with `hw new --space S --folder F --task
"<handoff>" --focus`, or `hw open-space --folder F --name N --claude --task
"<handoff>" --focus` when the folder is not a space yet. The handoff holds a
short summary, what he asked for and this session's ID, which `hw context
--session <id>` can expand. Then offer `hw done` on the old record if it held
nothing else. If the project's memory is still in `~`, offer to move its files
to the project's directory and mark it `own` in `scopes.json`. On the Mac or
outside herdr, tell him where to go instead of opening anything.

In a session launched in `~`, the prompt hook may add a `[memory] Project
routing` line on the first prompt. It is the signal for this offer: make the
offer it gives, as the whole reply. If he accepts, resume a matching record
from `hw ls`, else run the command the line gives; its `--task` is his prompt
verbatim, so the new session starts with it as its first message. If he
declines, stay and do not ask again.

Capture threshold — save deliberately, not eagerly. Save: durable
decisions, hard-won gotchas/runbooks and corrections/feedback. Project
status and pending work go in the project's `TODO.md` (`hw todo` lists and
edits it), not in memory. A topic with no project folder keeps its state in
the body of its memory file. Do not save: session ephemera, facts
derivable from a repo or config, one-off fixes. Update the existing
topic file over creating near-duplicates; delete what turns out wrong.
Every save/update must be mentioned in the reply ("saved to X") so it
can be vetoed — never write memory silently.

Index discipline: MEMORY.md holds hooks ONLY, never content — every
fact must live in a file. Editing a file includes refreshing its
frontmatter `description` (and review-by) in the same edit: the
breadcrumb when the file's use changed, the body and review-by when its
state did; the script
does the rest. If the generated index reports exceeding its size
tripwire (~120 lines), propose consolidation/archiving instead of
letting it grow.

Expiry/review: time-bound or staleness-prone files carry a
`review-by: YYYY-MM-DD — <what to check or ask>` line as the first body
line (or next to an individual fact). Always absolute dates; infer a
sensible date or ask when saving. At the start of substantive sessions
the generated index already surfaces overdue/imminent items — raise
them: "X is due — still true? / time to do it again?" Never silently
delete on expiry — ask, then update, re-date, or move the file to
`memory/archive/` (excluded from the index; history, not active
memory).

# Delegation

Source of truth: `~/projects/memory-server/claude/delegation.md` (want 9).

@~/projects/memory-server/claude/delegation.md
