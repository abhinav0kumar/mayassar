# anticlaude - design

## Why

AI coding assistants over-build. A fix that should be one line arrives as a new class,
three helpers and a config option. Asking the AI to clean up rarely helps: it tidies
around its own complexity instead of admitting the whole thing should be smaller.
After a few of these, the repo gets hard to find your way around, even for its owner.

anticlaude works the opposite way. It assumes AI work is bigger than it needs to be,
and it produces what a sensible human would have written: the smallest, plainest
change that does the job, put where a person would look for it.

## What it does

Two modes, both started with the `/anticlaude` command:

1. **Clean up.** After an AI finishes a branch, run `/anticlaude` on the diff.
   It works out what the change was actually trying to do, then rewrites it as
   the simplest change that does the same thing. It makes the change itself
   instead of just leaving comments.
2. **Build.** Give anticlaude a task directly. It builds it the simple way from
   the start, so you don't have to keep going back to an AI to fix what it made.
   This is the mode meant for everyday use.

The same applies to anything the AI wrote, not only code. Docs, READMEs and PR
descriptions get cut back to what a reader actually needs.

### Organising, two settings

- **Fix scope (default):** while cleaning or building, anticlaude also tidies
  the code the change touches: names, placement and dead bits. It leaves the
  rest of the repo alone. Over many changes the repo gets steadily cleaner,
  and no single bug fix shuffles the whole codebase.
- **Full scope (opt-in):** a deliberate restructure of the repo so it's easy
  to navigate. Only when explicitly asked.

## What "simple" means

- **Readable beats short.** The target is plain code that reads like a sentence.
  Character count is not a goal. Clever one-liners that have to be decoded
  inside-out are a failure, even when they're shorter.

  ```python
  # target
  emails = [u["email"] for u in users if u["status"] == "active" and u.get("email")]

  # failure — shorter in spirit, harder to read
  emails = [*filter(None, map(lambda u: u.get("email"), filter(lambda u: u.get("status") == "active", users)))]

  # what it replaces — a class wrapping a loop
  class UserEmailExtractor: ...
  ```
- No layers, wrappers, helpers or config that have only one use.
- Follow the repo's existing language and conventions. Don't impose a new style.

### What Clean up keeps (decided)

Only what the task asked for. Anything the AI added that nobody asked for
(extra settings, fallback paths, logging) is removed. Each clean-up ends with a
comparison of the original against anticlaude's version: what was kept, what was
removed and why, and the size difference, so it's clear why the result is better.

### Command or always-on (deferred)

To be decided once testing starts, likely as a setting. For the first version,
Build is a per-task command (`/anticlaude <task>`), the smallest thing to test with
(Claude's call).

## Must not get wrong

The simpler version must still do everything the task asked for. A short change
that quietly drops behaviour someone needed is worse than the bloat. Anything
removed shows up in the comparison, never silently.

## How we'll know it works

The main test is running in parallel. Give the same task to plain Claude and to
anticlaude, then compare:

1. **Still works:** both pass the same tests. A failing version loses, however
   small it is.
2. **Size:** lines changed, files touched, new layers or helpers added.
3. **Followable:** someone new to the code can find the change and understand it
   quickly.

If anticlaude keeps winning on 2 and 3 without losing on 1, that's the evidence,
and also the pitch if it's published.

**Competitors in the same comparison:** Anthropic's `code-simplifier` plugin and
Claude Code's built-in `/simplify`. Both tidy AI code while keeping everything it
does. anticlaude has to beat them on the same tasks, and the comparison should
show where it differs: it removes what the task didn't ask for, it explains each
cut, and it can build from scratch.

**Name (decided):** **mayasaar**. Modes: **jaam-naam** = redo what the AI did
(clean up); **nav-aam** = new code, tidying only what it touches (build);
**nav-khaas** = refactor the whole codebase (full). The README says in plain
English what each mode does; no translations needed.
Renaming the code from "anticlaude" is pending.

**Other AI tools (decided, details pending):** usable beyond Claude Code
(Codex, Cursor, Gemini CLI and similar), following ponytail's multi-tool layout.
Scope: all of them, i.e. every tool ponytail ships for (Codex, Cursor, Windsurf,
Cline, Kiro, OpenCode, Gemini CLI, GitHub Copilot, Qoder, Devin, OpenClaw, pi),
reusing its layout. The evals stay Claude Code-only.

**Earlier name notes:** "anticlaude" puts Anthropic's product name in a published
tool. "human" is taken by a Claude Code prose skill (tw93/human), and it lands in
the "AI humanizer" category, which conflicts with the anti-goal of disguising
AI work.

## Goals / non-goals / anti-goals

- **Goals:** smaller, plainer changes; a repo that gets easier to navigate over time;
  works on any repo; shareable publicly.
- **Non-goals:** enforcing one person's coding style; acting as a linter.
- **Anti-goals:** breaking behaviour to save lines; clever or cryptic code;
  reorganising a whole repo during a bug fix; disguising that AI wrote something.
  The aim is clarity, not hiding where the code came from.

## Constraints

- May be published, so it must not depend on any particular company, repo or
  internal tooling.

## Decided by Claude (open to change)

- **Form:** a Claude Code plugin with a `/anticlaude` command, installed the
  way existing plugins (e.g. ponytail) are, so it's easy to share.
- **Behaviour check:** anticlaude runs the repo's existing tests before and after
  its change.
- **No tests covering the change:** anticlaude first writes small tests that pin
  down what the original branch does, then checks the simplified version against
  them. These tests stay on the result branch and don't count toward the size score.
- **Tests already failing on the original:** anticlaude stops and reports this.
  It doesn't simplify on top of broken work.
- **Never overwrites the original:** results go on a new git branch. The AI's
  original branch stays untouched for comparison.
- **PR descriptions:** anticlaude prints a cut-down version for you to paste.
  It doesn't edit anything on GitHub.
- **Parallel comparison:** at first this is an evaluation tool for proving
  anticlaude works, not a feature shipped to users.
- **Not a git repo yet:** this folder isn't under git, so this document isn't
  committed.

## Left to the builder

- Exact command syntax for choosing mode and scope.
- How the parallel comparison is run and reported, e.g. separate worktrees
  and a short scorecard.
- The wording of the instructions that drive the simplification.
