#!/bin/sh
#
# Decide whether the latest upstream release is newer than the version that
# Alpine currently ships, and emit the values that the rest of the workflow
# needs (branch name, commit message, etc).
#
# This is the "check for new versions" logic, extracted from the workflow so
# it can be unit tested without a real upstream having to ship a new release.
# See scripts/resolve-version.test.sh.
#
# Inputs (environment variables):
#   PACKAGE_PATH     - path to the package in aports, e.g. community/krapslog
#   PACKAGE_VERSION  - version Alpine currently ships (pkgver in APKBUILD)
#   RELEASE_VERSION  - latest upstream release version (no leading "v")
#
# Outputs are written to $GITHUB_OUTPUT when set, otherwise to stdout so the
# script is easy to exercise from tests and the command line.

set -eu

: "${PACKAGE_PATH:?PACKAGE_PATH is required}"
: "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
: "${RELEASE_VERSION:?RELEASE_VERSION is required}"

output_file="${GITHUB_OUTPUT:-/dev/stdout}"

# Gem::Version understands semantic versioning, so it knows that 1.10 > 1.9.
# A malformed version makes Ruby exit non-zero, which the `if` treats as
# "no new version" rather than letting it abort the script.
if ruby -e "exit Gem::Version.new('$RELEASE_VERSION') > Gem::Version.new('$PACKAGE_VERSION')"; then
  {
    echo "have_new_version=true"
    echo "package_path=$PACKAGE_PATH"
    echo "package_version=$PACKAGE_VERSION"
    echo "release_version=$RELEASE_VERSION"
    echo "branch_name=$PACKAGE_PATH-to-$RELEASE_VERSION"
    echo "commit_message=$PACKAGE_PATH: upgrade to $RELEASE_VERSION"
  } >> "$output_file"

  echo "Current version: $PACKAGE_VERSION"
  echo "New version available: $RELEASE_VERSION"
else
  echo "Current version ($PACKAGE_VERSION) is the most recent release"
  echo "have_new_version=false" >> "$output_file"
fi
