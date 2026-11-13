Only follow these instructions when the user asks for mayassar (jaam-naam, nav-aam or nav-khaas). Otherwise ignore this file.

# mayassar

Assume the AI's work is bigger than it needs to be. Your job is the change a
sensible human would have written: the smallest, plainest one that does what the
task asked for, placed where a person would look for it.

## Modes (from the arguments)

- `jaam-naam`, or no args → **clean up**: redo what the AI did on the current branch.
- `nav-aam <task>` → **build** the task from scratch (see "Build" below).
- `nav-khaas` → **full scope**: restructure the whole repo so it's easy to navigate.
  If the current branch has an AI change (a diff against base), clean that up too;
  if not, skip the "nothing to clean up" stop and just restructure. Everything else
  (checks, tests before and after, report) is the same as clean up.
  Before moving anything, survey the repo and list each proposed move with its
  gain, its risk (including CI/deploy configs that match on file paths) and your
  call. The survey also covers unused code, code duplicated across files, and
  docs and comments that are wrong, stale, or about the AI's own design. List
  them like moves; don't reword ones that are just fine. Change nothing until
  the user picks which ones to do.
- Without `nav-khaas`, **fix scope**: tidy only code the change touches; leave
  every other file alone, however messy.

## Clean up

Do these in order. Each "stop" means: tell the user why, change nothing, end.

1. **Check you can start.**
   - `git status --porcelain` not empty → stop: there are uncommitted changes;
     ask them to commit or stash first. Never stash, reset, restore or check out
     over them yourself.
   - Base branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`,
     else `master`. None found → ask which branch to compare against.
   - `git diff <base>...HEAD` empty → stop: nothing to clean up.
2. **Find the task.** Read `git log <base>..HEAD` messages. If `gh` is available,
   also `gh pr view --json title,body`. If the task is still unclear, ask the user.
   The task decides what stays: anything the AI added that the task didn't ask
   for (extra settings, flags, fallbacks, logging, docs about its own design) goes.
3. **Run the tests on the original**, before editing anything. Find the runner the
   repo already uses. Failing → stop and name the failing tests; don't simplify
   broken work. If no test covers what the task asked for, write a small one first
   and make sure it passes against the original code.
4. **Work in place** on the current branch. Don't create a branch and don't commit:
   the user reviews and commits. The original stays in `HEAD`, so `git diff`
   shows exactly what you changed.
5. **Rewrite** to the smallest readable change that does the task. Rules below.
6. **Re-run the tests.** They must pass. Leave the changes uncommitted.
7. **Report** (see "Report").

## Rules for the rewrite

- **Readable beats short.** Fewer characters is never the goal. Plain code that
  reads like a sentence is. Reference:

  ```python
  # target: plain and short
  emails = [u["email"] for u in users if u["status"] == "active" and u.get("email")]

  # failure: shorter, but has to be decoded inside-out
  emails = [*filter(None, map(lambda u: u.get("email"), filter(lambda u: u.get("status") == "active", users)))]

  # what it replaces: a class wrapping a loop
  class UserEmailExtractor: ...
  ```
- No class, layer, wrapper, helper or config option with only one use.
- Nothing the change adds that nobody uses, and nothing it re-implements that the
  repo already has: call the existing code instead.
- Follow the repo's existing language, style and conventions.
- Docs and READMEs: cut to what a reader needs; drop text about the AI's own design.
- Tests that only exercise removed scaffolding (e.g. they test the deleted class):
  rewrite them to test what the task asked for. Never just delete them silently;
  they appear in the report. A rewritten test must also pass against the original
  code (check it with `git stash`-free means, e.g. `git worktree add` of `HEAD`), so the rewrite can't quietly change behaviour.
- Anything removed appears in the report. Nothing disappears quietly.

## Build (`/mayassar nav-aam <task>`)

The task is given; skip clean-up steps 2–3. From step 1, only the uncommitted-changes
check applies (dirty tree → stop); an empty diff against base is expected here.
Work on the current branch. Write a failing test for what the task asks, then the
smallest readable code that passes it, following the rules above. Run the tests,
leave the changes uncommitted, and report the files and lines added.

## Report

End with:

1. **Kept:** what stayed, one line each.
2. **Removed:** each removed item and why (usually "not asked for by the task"),
   including every test that was rewritten or removed, by name.
3. **Size:** `git diff --shortstat <base>...HEAD` (original) vs
   `git add -N . && git diff --shortstat <base>` (with your changes).
4. **Tests:** command run, result before and after.
5. **PR description** in a fenced block, a few lines, ready to paste. Don't edit
   anything on GitHub.
