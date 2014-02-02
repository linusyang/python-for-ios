#!/bin/bash
#  Python for iOS Cross Compile Script
#  Written by Linus Yang <laokongzi@gmail.com>
#
#  Credits:
#    http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
#    https://github.com/cobbal/python-for-iphone
#    http://www.trevorbowen.com/2013/10/07/cross-compiling-python-2-7-5-for-embedded-linux/
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

# set version
export PYVER="2.7.6"
export PYSHORT="2.7"
export NOWBUILD="2"

echo "[Cross compile Python ${PYVER} (Build ${NOWBUILD}) for iOS]"
echo "[Script by Linus Yang]"
echo ""

# sdk variable
export IOS_VERSION="5.1"
export DEVROOT=$("xcode-select" -print-path)"/Platforms/iPhoneOS.platform/Developer"
export SDKROOT="$DEVROOT/SDKs/iPhoneOS${IOS_VERSION}.sdk"

# other variable
export NOWDIR="$(cd "$(dirname "$0")" && pwd)"
export PRELIB="${NOWDIR}/libs-prebuilt-arm.tgz"
export SITELIB="${NOWDIR}/py27-site-packages.tgz"
export PRELIBFIX="/tmp"
export PRELIBLOC="$PRELIBFIX/prelib"
export LDIDLOC="$PRELIBLOC/usr/bin/ldid"
export DPKGLOC="$PRELIBLOC/usr/bin/dpkg-deb"
export FAKELOC="$PRELIBLOC/usr/bin/fakeroot"
export NATICC="/usr/bin/arm-apple-darwin9-gcc"
export NATICXX="/usr/bin/arm-apple-darwin9-g++"

# check dependency
cd "$NOWDIR"

if [ ! -d "$DEVROOT" ]; then
    echo "Fatal: DEVROOT doesn't exist. DEVROOT=$DEVROOT"
    exit 1
fi

if [ ! -d "$SDKROOT" ]; then
    echo "Fatal: SDKROOT doesn't exist. SDKROOT=$SDKROOT"
    exit 1
fi

if [ ! -f "$PRELIB" ]; then
    echo "Fatal: Missing prebuilt dependency libraries."
    exit 1
fi

# download python
echo '[Fetching Python source code]'
if [[ ! -a Python-${PYVER}.tar.xz ]]; then
    curl -O http://www.python.org/ftp/python/${PYVER}/Python-${PYVER}.tar.xz
fi

# extract dependency library
echo '[Extracting dependency libraries]'
rm -rf "${PRELIBLOC}"
tar zxf "${PRELIB}" -C "${PRELIBFIX}"

# get rid of old build
rm -rf Python-${PYVER}
tar Jxf Python-${PYVER}.tar.xz
pushd ./Python-${PYVER} > /dev/null 2>&1

# build for native machine
echo '[Building for host system]'
SAVESDK="$SDKROOT"
export SDKROOT=""
./configure > /dev/null 2>&1
make > /dev/null 2>&1
mv python.exe python.exe_for_build
mv Parser/pgen Parser/pgen_for_build
mv build "$PRELIBLOC/build_host"
mv pybuilddir.txt pybuilddir_host.txt
sed -i '' 's:build/:build_host/:g' pybuilddir_host.txt
make distclean > /dev/null 2>&1
export SDKROOT="$SAVESDK"

# patch python to cross-compile
patch -p1 < ../patches/Python-xcompile-${PYVER}.patch

# set up environment variables for cross compilation
export CPPFLAGS="-I$SDKROOT/usr/include/ -I$PRELIBLOC/usr/include"
export CFLAGS="$CPPFLAGS -pipe -isysroot $SDKROOT"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-isysroot $SDKROOT -miphoneos-version-min=3.0 -L$SDKROOT/usr/lib/ -L$PRELIBLOC/usr/lib"
export CC="$NATICC"
export CXX="$NATICXX"
export LD="$DEVROOT/usr/bin/ld"
export OPT="-DNDEBUG -O3 -Wall -Wstrict-prototypes"

# build for iphone
echo '[Cross compiling for Darwin ARM]'
./configure --prefix=/usr --enable-ipv6 --host=arm-apple-darwin --build=x86_64-apple-darwin --enable-shared --disable-toolbox-glue --with-signal-module --with-system-ffi --without-pymalloc ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no ac_cv_have_long_long_format=yes > /dev/null 2>&1
make
mv "$PRELIBLOC/build_host" .
make install prefix="$PWD/_install/usr" > /dev/null 2>&1
rm -rf "$PWD/_install/usr/share"

# sign binary with ldid
chmod +x "$LDIDLOC"
"$LDIDLOC" -S "$PWD/_install/usr/bin/python${PYSHORT}"

# symlink binary
cd "${NOWDIR}/Python-${PYVER}/_install/usr/bin"
ln -sf python${PYSHORT} python
sed -i '' "s:${NOWDIR}/Python-${PYVER}/_install::g" python${PYSHORT}-config
cd "${NOWDIR}"

# make debian package
if [ -x "$DPKGLOC" ]; then
    cd "${NOWDIR}/Python-${PYVER}/_install/"
    tar zxf "${SITELIB}"
    mkdir -p "DEBIAN"
    NOWSIZE="$(du -s -k usr | awk '{print $1}')"
    CTRLFILE="Package: com.linusyang.python27\nPriority: optional\nProvides: python\nConflicts: python\nReplaces: python\nSection: Scripting\nInstalled-Size: $NOWSIZE\nMaintainer: Linus Yang <laokongzi@gmail.com>\nSponsor: Linus Yang <http://linusyang.com/>\nArchitecture: iphoneos-arm\nVersion: ${PYVER}-$NOWBUILD\nDepends: berkeleydb, bzip2, libffi, ncurses, openssl, readline, sqlite3\nDescription: architectural programming language\nName: Python $PYSHORT\nHomepage: http://www.python.org/\nTag: purpose::console\n"
    PREFILE="#!/bin/sh\n/usr/libexec/cydia/move.sh /usr/lib/python${PYSHORT}\nexit 0\n"
    DEBNAME="com.linusyang.python27_${PYVER}-$NOWBUILD"
    echo -ne "$CTRLFILE" > DEBIAN/control
    echo -ne "$PREFILE" > DEBIAN/preinst
    chmod +x DEBIAN/preinst
    echo "[Packaging Debian Package]"
    cd ..
    export PATH="$PRELIBLOC/usr/bin:$PATH"
    "$FAKELOC" "$DPKGLOC" -bZ lzma _install "tmp.deb"
    mv -f tmp.deb ../$DEBNAME"_iphoneos-arm.deb"
    echo "[${DEBNAME}_iphoneos-arm.deb packaged successfully]"
fi

# clean build
rm -rf "${PRELIBLOC}"

echo "[All done]"
