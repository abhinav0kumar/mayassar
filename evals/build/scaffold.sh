#!/usr/bin/env bash
set -e
"$(dirname "$0")/../fixtures/emails/setup.sh" clean
git switch -q master
