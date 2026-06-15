# Maintainer: Example <example@example.com>
#
# Crafted edge-case fixture: some packages define a helper _pkgver= (e.g. when
# the upstream tag uses underscores) on a line that contains the substring
# "pkgver=". A naive `grep pkgver=` would match it; the anchored `^pkgver=`
# in parse-version.sh must select the real pkgver instead.
pkgname=example
_pkgver=1_2_3
pkgver=1.2.3
pkgrel=0
pkgdesc="Fixture only; not a real package"
url="https://example.com"
arch="all"
license="MIT"
source="https://example.com/$pkgname-$_pkgver.tar.gz"
