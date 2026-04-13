#!/usr/bin/env bash
# Enforce the project's branch naming convention.
#
# Allowed prefixes: feat/ fix/ docs/ chore/ refactor/ test/ deps/ ci/ step5/ step6/ step7/ step8/ step9/
# Exempt (always pass): main, master, develop, HEAD
set -euo pipefail

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

case "$BRANCH" in
  main|master|develop|HEAD)
    exit 0 ;;
esac

PATTERN='^(feat|fix|docs|chore|refactor|test|deps|ci|step[0-9]+)/'

if [[ "$BRANCH" =~ $PATTERN ]]; then
  exit 0
fi

echo "ERROR: branch '$BRANCH' does not match the allowed pattern."
echo "       Use one of: feat/ fix/ docs/ chore/ refactor/ test/ deps/ ci/ stepN/"
echo "       Example:    git checkout -b feat/add-search"
exit 1
