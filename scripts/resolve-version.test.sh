#!/bin/sh
#
# Unit tests for resolve-version.sh.
#
# These exercise the "check for new versions" decision with synthetic version
# pairs, so we never need a real upstream release to ship in order to gain
# confidence in the comparison and the values it derives.
#
# Run with: ./scripts/resolve-version.test.sh

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
RESOLVE="$SCRIPT_DIR/resolve-version.sh"

tests_run=0
tests_failed=0

# run_case <description> <package_path> <package_version> <release_version> \
#          <expected_have_new_version> [expected_branch_name]
run_case() {
  desc=$1
  pkg_path=$2
  pkg_ver=$3
  rel_ver=$4
  expected=$5
  expected_branch=${6:-}

  tests_run=$((tests_run + 1))

  out=$(mktemp)
  PACKAGE_PATH="$pkg_path" PACKAGE_VERSION="$pkg_ver" RELEASE_VERSION="$rel_ver" \
    GITHUB_OUTPUT="$out" sh "$RESOLVE" >/dev/null 2>&1

  have_new=$(grep '^have_new_version=' "$out" | head -n1 | cut -d= -f2)
  branch=$(grep '^branch_name=' "$out" | head -n1 | cut -d= -f2- || true)

  ok=1
  [ "$have_new" = "$expected" ] || ok=0
  if [ -n "$expected_branch" ] && [ "$branch" != "$expected_branch" ]; then
    ok=0
  fi

  if [ "$ok" -eq 1 ]; then
    echo "ok   - $desc"
  else
    tests_failed=$((tests_failed + 1))
    echo "FAIL - $desc"
    echo "         package_version=$pkg_ver release_version=$rel_ver"
    echo "         have_new_version: expected '$expected', got '$have_new'"
    if [ -n "$expected_branch" ]; then
      echo "         branch_name:      expected '$expected_branch', got '$branch'"
    fi
  fi

  rm -f "$out"
}

run_case "newer release is detected" \
  community/krapslog 0.5.0 0.6.0 true community/krapslog-to-0.6.0
run_case "identical versions are not an upgrade" \
  community/krapslog 0.6.0 0.6.0 false
run_case "older release is not an upgrade" \
  community/krapslog 0.6.0 0.5.0 false
run_case "a patch bump is detected" \
  community/krapslog 1.2.3 1.2.4 true
run_case "1.10 is newer than 1.9 (numeric, not lexical)" \
  main/libbpf 1.9 1.10 true
run_case "1.9 is not newer than 1.10 (numeric, not lexical)" \
  main/libbpf 1.10 1.9 false
run_case "a multi-component bump is detected" \
  community/bcc 0.29.1 0.30.0 true

echo ""
echo "$tests_run tests, $tests_failed failure(s)"
[ "$tests_failed" -eq 0 ]
