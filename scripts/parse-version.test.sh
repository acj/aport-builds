#!/bin/sh
#
# Unit tests for parse-version.sh.
#
# These exercise the "version fetch" parsing against saved fixtures and inline
# payloads, so we gain confidence in it without hitting the network or waiting
# on a real upstream release. The live network is covered separately by the
# contract job in .github/workflows/version-fetch-contract.yml.
#
# Run with: ./scripts/parse-version.test.sh

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PARSE="$SCRIPT_DIR/parse-version.sh"
FIX="$SCRIPT_DIR/fixtures"

tests_run=0
tests_failed=0

# assert_eq <description> <actual> <expected>
assert_eq() {
  desc=$1
  actual=$2
  expected=$3

  tests_run=$((tests_run + 1))
  if [ "$actual" = "$expected" ]; then
    echo "ok   - $desc"
  else
    tests_failed=$((tests_failed + 1))
    echo "FAIL - $desc"
    echo "         expected '$expected', got '$actual'"
  fi
}

# --- APKBUILD parsing (fixtures) ---
assert_eq "krapslog pkgver" \
  "$(sh "$PARSE" apkbuild < "$FIX/krapslog.APKBUILD")" "0.6.1"
assert_eq "bcc pkgver (ignores _llvmver=)" \
  "$(sh "$PARSE" apkbuild < "$FIX/bcc.APKBUILD")" "0.36.1"
assert_eq "anchoring ignores a _pkgver= helper line" \
  "$(sh "$PARSE" apkbuild < "$FIX/edge-underscore-pkgver.APKBUILD")" "1.2.3"

# --- GitHub release parsing (inline payloads) ---
assert_eq "release strips a leading v" \
  "$(printf '{"tag_name":"v0.6.1"}' | sh "$PARSE" release)" "0.6.1"
assert_eq "release without a v is unchanged" \
  "$(printf '{"tag_name":"0.6.1"}' | sh "$PARSE" release)" "0.6.1"
assert_eq "release keeps a non-leading v" \
  "$(printf '{"tag_name":"v2.0.0-preview"}' | sh "$PARSE" release)" "2.0.0-preview"

echo ""
echo "$tests_run tests, $tests_failed failure(s)"
[ "$tests_failed" -eq 0 ]
