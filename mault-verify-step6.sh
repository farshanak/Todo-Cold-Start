#!/usr/bin/env bash
# mault-verify-step6.sh — Ralph Loop verification for Step 6 (Pre-commit Hooks).
# Designed locally for this project (kit template was truncated in the prompt).
# 12 checks, exit 0 only when all pass.
set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0
CHECK_RESULTS=()
TOTAL_CHECKS=12

PROOF_DIR=".mault"
PROOF_FILE="$PROOF_DIR/verify-step6.proof"

record_result() { CHECK_RESULTS+=("CHECK $1: $2 - $3"); }
print_pass()    { echo "[PASS]    CHECK $1: $2"; PASS_COUNT=$((PASS_COUNT + 1)); record_result "$1" "PASS" "$2"; }
print_fail()    { echo "[FAIL]    CHECK $1: $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); record_result "$1" "FAIL" "$2"; }
print_pending() { echo "[PENDING] CHECK $1: $2"; PENDING_COUNT=$((PENDING_COUNT + 1)); record_result "$1" "PENDING" "$2"; }

# Staleness
if [ -f "$PROOF_FILE" ]; then
  PROOF_SHA=$(grep '^GitSHA:' "$PROOF_FILE" | awk '{print $2}')
  CURRENT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
  if [ "$PROOF_SHA" != "$CURRENT_SHA" ]; then
    echo "Stale proof (${PROOF_SHA} vs ${CURRENT_SHA}), deleting."
    rm -f "$PROOF_FILE"
  fi
fi

# Default branch
detect_default_branch() {
  local b
  b=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null) || true
  if [ -n "$b" ]; then echo "$b"; return; fi
  b=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/origin/@@') || true
  if [ -n "$b" ]; then echo "$b"; return; fi
  echo "main"
}
DEFAULT_BRANCH=$(detect_default_branch)

echo "========================================"
echo "  MAULT Step 6 Pre-commit Verification"
echo "  Default branch: $DEFAULT_BRANCH"
echo "========================================"

# CHECK 1: Step 5 prereq
check_1() {
  if [ ! -f ".mault/verify-step5.proof" ]; then
    print_fail 1 "Step 5 proof missing — complete Step 5 first."
    return
  fi
  print_pass 1 "Step 5 proof exists ($(grep '^Token:' .mault/verify-step5.proof | awk '{print $2}'))"
}

# CHECK 2: pre-commit CLI available
check_2() {
  if command -v pre-commit >/dev/null 2>&1; then
    print_pass 2 "pre-commit CLI on PATH ($(pre-commit --version))"
  else
    print_fail 2 "pre-commit CLI not installed."
  fi
}

# CHECK 3: config file
check_3() {
  if [ -f ".pre-commit-config.yaml" ]; then
    print_pass 3 "Config file .pre-commit-config.yaml exists"
  else
    print_fail 3 "No .pre-commit-config.yaml at repo root."
  fi
}

# CHECK 4: git hook installed
check_4() {
  if [ -x ".git/hooks/pre-commit" ] && grep -q 'pre-commit' .git/hooks/pre-commit 2>/dev/null; then
    print_pass 4 ".git/hooks/pre-commit installed and references pre-commit"
  else
    print_fail 4 "Git hook missing or not wired to pre-commit."
  fi
}

# CHECK 5: branch-name script
check_5() {
  if [ -x "scripts/check-branch-name.sh" ]; then
    print_pass 5 "scripts/check-branch-name.sh present and executable"
  else
    print_fail 5 "scripts/check-branch-name.sh missing or not executable."
  fi
}

# CHECK 6: secrets baseline exists
check_6() {
  if [ -f ".secrets.baseline" ]; then
    print_pass 6 ".secrets.baseline exists"
  else
    print_fail 6 "Missing .secrets.baseline — run: detect-secrets scan > .secrets.baseline"
  fi
}

# CHECK 7: pre-commit run --all-files exits 0
check_7() {
  local out
  out=$(pre-commit run --all-files 2>&1)
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    print_pass 7 "pre-commit run --all-files exits 0"
  else
    print_fail 7 "pre-commit run --all-files failed (exit $rc). Fix and recommit."
  fi
}

# CHECK 8: validate-pr-title job in CI
check_8() {
  if grep -qE '^\s*validate-pr-title:' .github/workflows/ci.yml 2>/dev/null; then
    print_pass 8 "validate-pr-title job declared in ci.yml"
  else
    print_fail 8 "validate-pr-title job missing from .github/workflows/ci.yml"
  fi
}

# CHECK 9: validate-branch-name job in CI
check_9() {
  if grep -qE '^\s*validate-branch-name:' .github/workflows/ci.yml 2>/dev/null; then
    print_pass 9 "validate-branch-name job declared in ci.yml"
  else
    print_fail 9 "validate-branch-name job missing from .github/workflows/ci.yml"
  fi
}

# CHECK 10: [mault-step6] handshake commit exists
check_10() {
  local c
  c=$(git log --all --format='%h %s' 2>/dev/null | grep -F '[mault-step6]' | head -1)
  if [ -n "$c" ]; then
    print_pass 10 "Handshake commit present: ${c}"
  else
    print_fail 10 "No commit with [mault-step6] marker found in history."
  fi
}

# CHECK 11: branch protection includes new checks
check_11() {
  local owner repo protection
  owner=$(gh repo view --json owner -q '.owner.login' 2>/dev/null) || true
  repo=$(gh repo view --json name -q '.name' 2>/dev/null) || true
  if [ -z "$owner" ] || [ -z "$repo" ]; then
    print_pending 11 "Cannot query gh repo — skipping."
    return
  fi
  protection=$(gh api "repos/${owner}/${repo}/branches/${DEFAULT_BRANCH}/protection/required_status_checks" -q '.contexts[]' 2>/dev/null) || true
  if [ -z "$protection" ]; then
    print_fail 11 "No required status checks on ${DEFAULT_BRANCH}."
    return
  fi
  local missing=""
  echo "$protection" | grep -qF "validate-pr-title" || missing="${missing} validate-pr-title"
  echo "$protection" | grep -qF "validate-branch-name" || missing="${missing} validate-branch-name"
  if [ -n "$missing" ]; then
    print_fail 11 "Branch protection missing required checks:${missing}"
    return
  fi
  print_pass 11 "Branch protection includes validate-pr-title and validate-branch-name"
}

# CHECK 12: handshake issue
check_12() {
  if ! command -v gh >/dev/null 2>&1; then
    print_pending 12 "gh not available"
    return
  fi
  local issue_url
  issue_url=$(gh issue list --search "[MAULT] Production Readiness: Step 6" --json url -q '.[0].url' 2>/dev/null) || true
  if [ -z "$issue_url" ]; then
    issue_url=$(gh issue list --state closed --search "[MAULT] Production Readiness: Step 6" --json url -q '.[0].url' 2>/dev/null) || true
  fi
  if [ -n "$issue_url" ]; then
    print_pass 12 "Handshake issue: ${issue_url}"
  else
    print_pending 12 "No handshake issue found."
  fi
}

check_1; check_2; check_3; check_4; check_5; check_6
check_7; check_8; check_9; check_10; check_11; check_12

echo ""
echo "========================================"
echo "  PASS: ${PASS_COUNT}/${TOTAL_CHECKS}  FAIL: ${FAIL_COUNT}/${TOTAL_CHECKS}  PENDING: ${PENDING_COUNT}/${TOTAL_CHECKS}"
echo "========================================"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
  epoch=$(date +%s)
  token="MAULT-STEP6-${sha}-${epoch}-${TOTAL_CHECKS}/${TOTAL_CHECKS}"
  mkdir -p "$PROOF_DIR"
  [ -f "$PROOF_DIR/.gitignore" ] || printf '*\n!.gitignore\n' > "$PROOF_DIR/.gitignore"
  {
    echo "MAULT-STEP6-PROOF"
    echo "=================="
    echo "Timestamp: $epoch"
    echo "GitSHA: $sha"
    echo "Checks: ${TOTAL_CHECKS}/${TOTAL_CHECKS} PASS"
    for r in "${CHECK_RESULTS[@]}"; do echo "  $r"; done
    echo "=================="
    echo "Token: $token"
  } > "$PROOF_FILE"
  echo "Proof file written: $PROOF_FILE"
  echo "Token: $token"
  echo "ALL CHECKS PASSED. Step 6 Pre-commit is complete."
  exit 0
elif [ "$FAIL_COUNT" -gt 0 ]; then
  rm -f "$PROOF_FILE"
  echo "${FAIL_COUNT} check(s) FAILED. Fix and re-run: ./mault-verify-step6.sh"
  exit 1
else
  rm -f "$PROOF_FILE"
  echo "${PENDING_COUNT} check(s) PENDING. Complete work and re-run."
  exit 1
fi
