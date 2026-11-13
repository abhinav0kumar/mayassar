#!/usr/bin/env bash
# Runs the clean-up case against a competitor plugin on its own (no mayasaar loaded).
# Usage: evals/compete.sh <competitor-plugin-dir> [extra eval flags...]
# The eval runner only loads plugins under the target dir, so we stage a throwaway copy.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
competitor="$1"; shift
stage="$(mktemp -d)/$(basename "$competitor")"
cp -R "$competitor" "$stage"
mkdir -p "$stage/evals"
cp -R "$here/clean-up" "$here/fixtures" "$stage/evals/"
sed -i.bak 's/Clean it up\./Clean it up with the code-simplifier agent./' "$stage/evals/clean-up/case.yaml"
sed -i.bak 's/allowed_tools: \[Bash, Read, Edit, Write, Glob, Grep, Skill\]/allowed_tools: [Bash, Read, Edit, Write, Glob, Grep, Skill, Agent]/' "$stage/evals/clean-up/case.yaml"
rm "$stage/evals/clean-up/case.yaml.bak"
claude plugin eval "$stage" --scaffold --trust-plugin --no-publish --ablation none \
  --allow-tools Bash Edit Write Agent "$@"
