# anticlaude Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Claude Code plugin whose `/anticlaude` skill cuts AI-written changes back to the smallest readable version (clean up), or builds a task that way from the start (build).

**Architecture:** The product is one skill file, `skills/anticlaude/SKILL.md`. It holds the instructions and has no runtime code. It is tested with Claude Code's built-in `claude plugin eval`. Each eval case sets up a small throwaway git repo, using a fixture script, that contains a bloated AI branch. It runs the case with and without the plugin. The "without" arm is the side-by-side comparison against plain Claude that the spec asks for.

**Tech Stack:** Claude Code plugin (markdown + JSON), bash fixture scripts, Python 3 stdlib `unittest` inside the fixture repo, `claude plugin eval` / `claude plugin validate`.

**Spec:** `docs/superpowers/specs/2026-11-13-anticlaude-design.md`

## Global Constraints

- Nothing company-, repo- or tool-specific in the plugin. It must work on any git repo ("May be published").
- Readable beats short: target `emails = [u["email"] for u in users if u["status"] == "active" and u.get("email")]`; nested `filter`/`map`/`lambda` one-liners are a failure.
- Never modify the original branch; results go on a new branch.
- Clean up keeps only what the task asked for; every removal appears in the comparison, never silently.
- Fix scope (default) touches only code the change touches; full scope only when explicitly asked.
- PR descriptions are printed for pasting; nothing is edited on GitHub.
- No runtime dependencies. Fixtures use only bash, git and Python stdlib.
- Command syntax (Claude's call, settles "left to the builder"): `/anticlaude` = clean up the current branch; `/anticlaude build <task>` = build; the word `full` anywhere in the args = full scope.

## Review Focus

1. **Uncommitted changes in the working tree.** Stop and say so. Never stash, reset or check out over them. *(Task 3)*
2. **The AI branch's tests already fail.** Stop before changing anything and report which tests fail. *(Task 3)*
3. **Tests that only exercise the AI's removed scaffolding** (e.g. they test the class anticlaude deletes). Rewrite them to test what the task asked for, and list that in the comparison. Don't delete them silently. *(Task 2, fixture tests are written this way on purpose)*
4. **The target branch `anticlaude/<name>` already exists.** Use `-2`, `-3`…; never overwrite. *(Task 3 step)*
5. **No base branch found** (no `origin/HEAD`, `main` or `master`). Ask the user; don't guess. *(Task 3, skill text; not evaled, so check it in review)*

---

### Task 1: Repo and plugin skeleton

**Files:**
- Create: `.gitignore` (`evals/results/`)
- Create: `.claude-plugin/plugin.json`: `{"name": "anticlaude", "version": "0.1.0", "description": "Cuts AI-written changes back to the smallest readable version a human would have written."}`
- Create: `.claude-plugin/marketplace.json`: same shape as ponytail's (`~/.claude/plugins/cache/ponytail/ponytail/4.8.4/.claude-plugin/marketplace.json`), one plugin, `"source": "./"`, owner left as a `TODO` for the user to fill before publishing.
- Create: `README.md`: what it does, install (`claude --plugin-dir .` for local use), the three command forms. Under 40 lines.

- [ ] **Step 1:** `git init -b master` in the project root.
- [ ] **Step 2:** Create the files above.
- [ ] **Step 3:** Run `claude plugin validate .`. Expected: exit 0 with no errors. A warning that there are no skills yet is fine.
- [ ] **Step 4:** Commit everything, including `docs/`: `chore: plugin skeleton and design`.

### Task 2: Eval fixture

**Files:**
- Create: `evals/fixtures/emails/setup.sh` (executable). It builds a git repo in the current directory. An optional first arg selects a variant: `clean` (default), `failing` or `dirty`.

**Interfaces:**
- Produces: running `setup.sh [variant]` in an empty dir leaves a repo on branch `ai/active-emails` with base `master`, where:
  - `master`: `users.py` (`USERS` list of dicts with `name`, `email`, `status`, all synthetic, e.g. `ada@example.com`); `legacy.py` containing the line `def DoThing(x):  # sentinel-legacy` plus some deliberately messy unrelated code; `test_users.py` (one passing test on `USERS`); `README.md` (3 lines).
  - `ai/active-emails`: one commit, message `Add active_emails: return the emails of active users`. Adds `UserEmailExtractor` class + `EmailConfig` with an unused `include_inactive` flag + a `logging` setup to `users.py` (the unrequested extras); adds a ~25-line "Email extraction architecture" section to `README.md`; adds tests in `test_users.py` that call `UserEmailExtractor(USERS).extract()`.
  - `failing`: same, but one ai-branch test asserts a wrong email.
  - `dirty`: same as `clean`, plus an uncommitted edit to `README.md`.

- [ ] **Step 1:** Write `setup.sh`. Use `git -c user.name=fixture -c user.email=fixture@example.com` so it works without git config.
- [ ] **Step 2:** Verify each variant in a scratch dir:
  - `clean`: `python3 -m unittest` → `OK`; `git log --oneline master..ai/active-emails` → 1 line.
  - `failing`: `python3 -m unittest` → `FAILED (failures=1)`.
  - `dirty`: `git status --porcelain` → ` M README.md`.
- [ ] **Step 3:** Commit: `test: emails eval fixture`.

### Task 3: Clean-up mode

**Files:**
- Create: `skills/anticlaude/SKILL.md`
- Create: `evals/clean-up/case.yaml`, `evals/stop-failing-tests/case.yaml`, `evals/stop-dirty-tree/case.yaml`

**Interfaces:**
- Consumes: `evals/fixtures/emails/setup.sh [variant]` (Task 2).
- Produces: skill name `anticlaude`. Its frontmatter `description` must trigger on "/anticlaude", "clean up / simplify what the AI wrote", "this is over-engineered" and "build X the simple way".

- [ ] **Step 1: Write the three eval cases (failing first: no skill exists yet).** Use `schema_version: "1.1"`, `context.scaffold_script` running the fixture (`clean` / `failing` / `dirty`), `execution.allowed_tools: [Bash, Read, Edit, Write, Glob, Grep, Skill]`, `max_turns: 60`, `timeout_seconds: 900`. Prompt for all three: `The AI just finished the change on this branch. Clean it up.` Graders:
  - `clean-up`:
    - `tool_used` Skill, `arm: with-only`
    - regex `target: files`: `class UserEmailExtractor` → `not_contains`
    - regex `target: files`: `include_inactive` → `not_contains`
    - regex `target: files`: `def DoThing\(x\):  # sentinel-legacy` → `contains` (fix scope left `legacy.py` alone)
    - llm `focus: trace`: "Tests were run on the original branch before any edit and on a new branch named `anticlaude/ai/active-emails` after; they pass after. No commit was made to `ai/active-emails`."
    - llm `focus: last_message`: "Ends with a comparison: what was kept, each removed item (the class, `include_inactive`, logging, the README section) with a reason, and diff size for both branches. Includes a short PR description to paste. The resulting code is a plain readable function, not a nested filter/map/lambda chain."
  - `stop-failing-tests`: llm last_message "Stopped before editing and named the failing test"; llm trace "No new branch was created and no files were edited".
  - `stop-dirty-tree`: llm last_message "Stopped and said there are uncommitted changes"; regex `target: trace` `git (stash|reset|checkout -- )` → `not_contains`.
- [ ] **Step 2:** Run `claude plugin eval . --scaffold --trust-plugin --no-publish --runs 1 --allow-tools Bash Edit Write`. Expected: the with-plugin arm fails `tool_used`, because there's no skill yet. On this first run, check with `--keep-temp` that the scaffold ran in the workspace and the repo exists. Fix the `scaffold_script` path if not.
- [ ] **Step 3: Write `SKILL.md`.** It must contain, in this order:
  1. **Refuse to start** when: the tree is dirty (→ stop, say so; never stash/reset); there is no base branch from `git symbolic-ref refs/remotes/origin/HEAD`, `main` or `master` (→ ask); there is no diff vs base (→ say so).
  2. **Find the task:** commit messages in `base..HEAD`, then `gh pr view --json body` if `gh` exists, else ask the user.
  3. **Run the tests on the original.** Failing → stop and report. No tests touch the changed code → write small tests that pin down *what the task asked for* first.
  4. **Branch:** `git switch -c anticlaude/<current-branch>` (suffix `-2`, `-3` if taken).
  5. **Rewrite** to the smallest readable change that does the task. Rules: readable beats short (include the spec's A/B/C example verbatim as the reference); no single-use layers/wrappers/helpers/config; follow the repo's conventions; docs and READMEs cut to what a reader needs; tests that only exercise removed scaffolding are rewritten to test the task. Fix scope: tidy only the touched code. With `full` in args: restructure the repo for navigability, still behaviour-preserving.
  6. **Re-run tests;** they must pass. Commit on the new branch.
  7. **Report:** kept / removed-and-why / `git diff --shortstat <base>...<original>` vs `<base>...HEAD`, then a PR description in a fenced block to paste.
- [ ] **Step 4:** Re-run the eval from Step 2. Expected: all three cases at 1.0 on the with-plugin arm. The report also shows the without-plugin arm's scores; record them in the commit message.
- [ ] **Step 5:** Commit: `feat: clean-up mode`.

### Task 4: Build mode and full scope

**Files:**
- Modify: `skills/anticlaude/SKILL.md` (add the build branch of the instructions)
- Create: `evals/build/case.yaml`, `evals/full-scope/case.yaml`

- [ ] **Step 1: Write the cases.**
  - `build`: scaffold runs the fixture, then `git switch master`. Prompt: `/anticlaude build add a function that returns the emails of active users`. Graders: regex files `class \w*Extractor` → `not_contains`; regex files sentinel-legacy → `contains`; llm trace "A test for the new function was added and passes; work is on a new `anticlaude/` branch"; llm last_message "The function is plain and readable (comprehension or simple loop), with no config or logging added".
  - `full-scope`: fixture `clean`. Prompt: `/anticlaude full`. Graders: regex files sentinel-legacy → `not_contains` (legacy was tidied); llm trace "Tests pass after the restructure".
- [ ] **Step 2:** Run with `--case build --case full-scope` (same flags as Task 3). Expected: `build` fails or skips the branch/test checks.
- [ ] **Step 3:** Add build mode to `SKILL.md`: on `build <task>`, skip steps 2–3 of clean-up (use the given task; start from the current branch). Branch `anticlaude/<slug-of-task>`. Write the failing test first, then the smallest readable code, tests pass, commit, and report the files and lines added.
- [ ] **Step 4:** Re-run the whole suite. Expected: all five cases at 1.0 with the plugin.
- [ ] **Step 5:** Commit: `feat: build mode and full scope`.

### Task 5: Comparison readout against plain Claude and competitors

Four contenders on the `clean-up` case, same fixture, same graders: anticlaude, plain Claude (the eval's without-plugin arm), `code-simplifier@claude-plugins-official`, and built-in `/simplify`.

- [ ] **Step 1:** Find out how to point the same case at a different plugin. Candidates: the case's `plugins:` field, or `claude plugin eval code-simplifier@claude-plugins-official --eval-dir ...`. For `/simplify`, which is built in, add a copy of `clean-up` whose prompt is `/simplify`, run without the plugin. Use whichever works with the fewest extra files.
- [ ] **Step 2:** Run all four at `--runs 3`, writing reports to `evals/results/`.
- [ ] **Step 3:** Add a "Results" section to `README.md` with a table: contender × (still works, lines changed, removed unrequested extras y/n, explained cuts y/n).
- [ ] **Step 4:** Commit: `docs: comparison against plain Claude, code-simplifier, /simplify`.

### Task 6 (added 2026-11-13, user request): Rename to mayasaar

- Plugin, skill and branches renamed to `mayasaar`. Modes: `jaam-naam` (default) = clean up, `nav-aam <task>` = build, `nav-khaas` = full scope. Eval prompts and graders updated; suite re-run.

### Task 7 (added 2026-11-13, user request): Other AI tools

- `scripts/sync_adapters.py` generates each tool's file from `skills/mayasaar/SKILL.md`; `--check` is the test. Tools: Codex, Qoder, Devin, GitHub Copilot, Gemini CLI, OpenCode, OpenClaw, Cursor, Windsurf, Kiro, Cline, pi/AGENTS.md.
