#!/bin/sh
#
# Extract a version string from upstream data on stdin. Keeping the parsing
# separate from the `curl` that fetches the data is what lets us unit test it
# against saved fixtures, with no network and no real upstream release.
# See scripts/parse-version.test.sh.
#
#   parse-version.sh apkbuild  < APKBUILD       -> the version Alpine ships (pkgver)
#   parse-version.sh release   < releases.json  -> upstream release (no leading v)

set -eu

case "${1:-}" in
  apkbuild)
    # Anchor to ^pkgver= so a helper like _pkgver= (which still contains the
    # substring "pkgver=") can't be mistaken for the real version.
    grep -E '^pkgver=' | head -n1 | sed -E 's/^pkgver=//'
    ;;
  release)
    # Strip only a *leading* v, unlike `tr -d 'v'`, which deletes every v and
    # would corrupt versions such as 2.0.0-preview.
    jq -r '.tag_name' | sed -E 's/^v//'
    ;;
  *)
    echo "usage: $0 {apkbuild|release}" >&2
    exit 2
    ;;
esac
