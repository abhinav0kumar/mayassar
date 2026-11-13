# mayassar

**mayassar** (Urdu: میسّر, "made easy; within reach"): code that's easy to read is
code anyone can work with.

AI coding assistants over-build. mayassar cuts their work back to the smallest,
plainest change that does what the task asked for, and shows what it cut and why.

## Why

A fix that is one line arrives as a story instead, all jumbled and bloated. Ask the AI to clean it up and it tidies around its own complexity instead
of admitting the whole thing should be smaller, even after several passes. Over
time the repo gets hard to find your way around, even for the person who owns it.

Everyone codes differently, but simple, well-organised code is something anyone
can understand and work with. mayassar assumes the AI's work is bigger than it
needs to be and produces what a sensible human would have written.

## Modes

| Command | What it does |
|---|---|
| `/mayassar jaam-naam` (or just `/mayassar`) | Takes what the AI did on this branch and redoes it as the smallest readable change, then explains each cut. |
| `/mayassar nav-aam <task>` | Writes new code the simple way, and tidies only the code it touches. |
| `/mayassar nav-khaas` | Restructures the whole codebase so it's easy to find your way around, and cleans up the branch's AI change if there is one. Only when you ask. |

Changes are left uncommitted on your branch for you to review and commit. Nothing is committed or pushed for you.

## Rules it follows

- Readable beats short. No clever one-liners.
- Keep only what the task asked for. Every removal is listed with a reason.
- Tests run before and after. If they already fail, it stops.
- Uncommitted changes? It stops and never stashes or discards them.

## Install (Claude Code)

```
/plugin marketplace add abhinav0kumar/mayassar
/plugin install mayassar@mayassar
```

From a local clone: `claude --plugin-dir /path/to/mayassar`.

## Other tools

`skills/mayassar/SKILL.md` is the single source. `python3 scripts/sync_adapters.py`
generates each tool's copy; `--check` fails if any is out of date.

| Tool | How |
|---|---|
| Codex, Qoder, Devin, GitHub Copilot | plugin manifests in `.codex-plugin/`, `.qoder-plugin/`, `.devin-plugin/`, `.github/plugin/`, loading `skills/` |
| Gemini CLI | extension `gemini-extension.json`, command `/mayassar` in `commands/mayassar.toml` |
| OpenCode | command `.opencode/command/mayassar.md` |
| OpenClaw | skill `.openclaw/skills/mayassar/` |
| Cursor, Windsurf, Kiro, Cline | copy `.cursor/rules/mayassar.mdc`, `.windsurf/rules/mayassar.md`, `.kiro/steering/mayassar.md` or `.clinerules/mayassar.md` into your project |
| pi and anything that reads `AGENTS.md` | `AGENTS.md` |

Only Claude Code is covered by the automated evals. The other tools haven't been
tried by hand yet.

## Results so far

Same bloated AI branch for everyone (a class, an unrequested setting, logging and a
30-line README section around a one-line task). Judge: Sonnet.

- **Neutral checks** (any tool can pass): bloat removed, unrelated code left alone,
  tests run first, plain readable code.
- **All checks** adds mayassar's own promises: nothing committed for you, cuts and
  rewritten tests explained, size compared, PR description. Competitors don't
  attempt these, so that column shows what mayassar adds, not a fair contest.

| Contender | Neutral checks | All checks | Runs |
|---|---|---|---|
| **mayassar** | **1.00** | **1.00** | 2 |
| code-simplifier (Anthropic plugin) | 1.00 | 0.63 | 1 |
| `/simplify` (built into Claude Code) | 0.63 | 0.44 | 2 |
| plain Claude | 0.63 | 0.38 | 2 |

Honest read: code-simplifier matched mayassar on the neutral checks in its one
Sonnet-judged run (in an earlier run it kept the bloat). More runs are needed
before claiming mayassar simplifies better; today its clear edge is the safety net
and the explanation: nothing committed for you, explained cuts, size comparison, PR text.
(Scores predate two checks added after review, rewritten tests named and original
branch untouched, and the switch from a new branch to uncommitted changes.)

Other mayassar checks (Haiku judge, 2 runs, all 1.00): nav-aam builds test-first
with no extras; nav-khaas tidies the wider repo; stops when tests already fail;
stops on uncommitted changes without stashing them.

Run the evals: `claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Edit Write`.
Competitor run: `evals/compete.sh <plugin-dir>`. The evals currently assume macOS
(they point git at the Command Line Tools binary, because the eval sandbox blocks
`/usr/bin/git`).
