#!/bin/bash
# Python for iOS Cross Compile Script Version 0.1
# Written by Linus Yang <laokongzi@gmail.com>
#
# Credit to:
# http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
# https://github.com/cobbal/python-for-iphone
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

set -o errexit

# set version
export PYVER="2.7.3"
if [ -n "$1" ]; then
    export PYVER="$1"
fi
export NOWBUILD="1"
if [ -n "$2" ]; then
    export NOWBUILD="$2"
fi

echo "[Cross compile Python ${PYVER} (Build ${NOWBUILD}) for iOS]"
echo "[Script version 0.1 by Linus Yang]"
echo ""

# sdk variable
export IOS_VERSION="4.2"
export DEVROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
export SDKROOT="$DEVROOT/SDKs/iPhoneOS${IOS_VERSION}.sdk"
export HOSTCC="$DEVROOT/usr/bin/arm-apple-darwin10-gcc-4.2.1"
export HOSTCXX="$DEVROOT/usr/bin/arm-apple-darwin10-g++-4.2.1"
export GCCINCLUDE="$SDKROOT/usr/lib/gcc/arm-apple-darwin10/4.2.1/include/"

# other variable
export NOWDIR="$(dirname "$0")"
export PYSHORT=${PYVER:0:3}
export PROXYHEAD="$SDKROOT/System/Library/Frameworks/SystemConfiguration.framework/Headers"
export LDIDLOC="$NOWDIR/ldid"
export PRELIB="${NOWDIR}/libs-prebuilt-arm.tgz"
export PRELIBLOC="${NOWDIR}/prelib"
export DPKGLOC="$(which dpkg-deb)"
export NATICC="/usr/bin/arm-apple-darwin9-gcc-4.2.1"
export NATICXX="/usr/bin/arm-apple-darwin9-g++-4.2.1"

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

if [ ! -f "$LDIDLOC" ]; then
    echo "Fatal: Missing binary ldid."
    exit 1
fi

if [ ! -f "$PRELIB" ]; then
    echo "Fatal: Missing prebuilt dependency libraries."
    exit 1
fi

if [ ! -f "$NATICC" ]; then
    echo "[Make workaround gcc symlink]"
    echo "[* Need root privilege, type your password *]"
    sudo ln -s "$HOSTCC" "$NATICC"
    echo "Symlink is made."
fi

if [ ! -f "$NATICXX" ]; then
    echo "[Make workaround gcc symlink]"
    echo "[* Need root privilege, type your password *]"
    sudo ln -s "$HOSTCXX" "$NATICXX"
    echo "Symlink is made."
fi

# download python
echo '[Fetching Python source code]'
if [[ ! -a Python-${PYVER}.tgz ]]; then
    curl -O http://www.python.org/ftp/python/${PYVER}/Python-${PYVER}.tgz
fi

# extract dependency library
echo '[Extracting dependency libraries]'
rm -rf ${PRELIBLOC}
mkdir -p ${PRELIBLOC} && cd ${PRELIBLOC}
tar zxf ${PRELIB}
cd ..

# patch xcode header
if [ "${PYSHORT}" '>' "2.6" ]; then
    echo "[Patching Xcode header to enable scproxy module]"
    echo "[* Need root privilege, type your password *]"
    cd "$PROXYHEAD"
    sudo cp SCSchemaDefinitions.h SCSchemaDefinitions-now.h
    if ! sudo patch -Np1 < "$NOWDIR/patches/Python-xcode-scproxy.patch"; then
        echo "[Warning: Patching failed]"
        sudo rm -f SCSchemaDefinitions-now.h SCSchemaDefinitions.h.rej
    else
        sudo mv -f SCSchemaDefinitions-now.h SCSchemaDefinitions-org.h
    fi
    cd "$NOWDIR"
fi

# get rid of old build
rm -rf Python-${PYVER}
tar zxf Python-${PYVER}.tgz
pushd ./Python-${PYVER}

# ctypes patch for python 2.6
if [ "${PYSHORT}" = "2.6" ]; then
    echo "[Applying ctypes patching for Python 2.6]"
    patch -p1 < ../patches/Python-ctypes-2.6.patch
fi

# build for native machine
echo '[Building for host system]'
./configure --prefix="$PWD/_install_host/usr" --enable-shared --enable-ipv6 --disable-toolbox-glue
make python.exe Parser/pgen
mv python.exe hostpython
mv Parser/pgen Parser/hostpgen
mv libpython${PYSHORT}.a hostlibpython${PYSHORT}.a
make install HOSTPYTHON=./hostpython
make distclean

# patch python to cross-compile
patch -p1 < ../patches/Python-xcompile-${PYVER}.patch

# set up environment variables for cross compilation
export CPPFLAGS="-I${GCCINCLUDE} -I$SDKROOT/usr/include/ -I$PRELIBLOC/usr/lib"
export CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-isysroot $SDKROOT -miphoneos-version-min=3.0 -L$SDKROOT/usr/lib/ -L$PRELIBLOC/usr/lib"
export CPP="/usr/bin/cpp"
export CC="$NATICC"
export CXX="$NATICXX"
export LD="$DEVROOT/usr/bin/ld"

# build for armv6
echo '[Cross compiling for Darwin ARM]'
./configure --prefix=/usr --enable-ipv6 --host=armv6-apple-darwin --enable-shared --disable-toolbox-glue --with-signal-module --with-system-ffi
make HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen CROSS_COMPILE_TARGET=yes
make install HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="$PWD/_install/usr"
find "$PWD/_install/usr/lib/python${PYSHORT}" -type f -name *.pyc -exec rm -f {} \;
find "$PWD/_install/usr/lib/python${PYSHORT}" -type f -name *.pyo -exec rm -f {} \;
rm -rf "$PWD/_install/usr/share"

# sign binary with ldid
chmod +x "$LDIDLOC"
"$LDIDLOC" -S "$PWD/_install/usr/bin/python${PYSHORT}"

# symlink binary
cd "${NOWDIR}/Python-${PYVER}/_install/usr/bin"
ln -sf python${PYSHORT} python
sed -i '' "s:${NOWDIR}/Python-${PYVER}/_install::g" python${PYSHORT}-config
cd "${NOWDIR}"

# reverse patched xcode header
if [ "${PYSHORT}" '>' "2.6" ]; then
    echo "[Reverse patch for Xcode header file]"
    echo "[* Need root privilege, type your password *]"
    cd "${PROXYHEAD}"
    sudo mv -f SCSchemaDefinitions-org.h SCSchemaDefinitions.h
    cd "${NOWDIR}"
fi

# make debian package
if [ -n "$DPKGLOC" ]; then
    cd "${NOWDIR}/Python-${PYVER}/_install/"
    mkdir -p "DEBIAN"
    NOWSIZE=$(du -s -k usr | grep --color=never -o '[0-9]\+')
    CTRLFILE="Package: python\nPriority: optional\nSection: Scripting\nInstalled-Size: $NOWSIZE\nMaintainer: Linus Yang <laokongzi@gmail.com>\nSponsor: Linus Yang <http://linusyang.com/>\nArchitecture: iphoneos-arm\nVersion: ${PYVER}-$NOWBUILD\nPre-Depends: cydia (>= 1.0.2355-38)\nDepends: berkeleydb, bzip2, libffi, ncurses, openssl, readline, sqlite3\nDescription: architectural programming language (with IPv6 support)\nName: Python\nHomepage: http://www.python.org/\nTag: purpose::console, role::developer\n"
    PREFILE="#!/bin/bash\n/usr/libexec/cydia/move.sh /usr/lib/python${PYSHORT}\nexit 0"
    DEBNAME="python_${PYVER}-$NOWBUILD"
    echo -ne "$CTRLFILE" > DEBIAN/control
    echo -ne "$PREFILE" > DEBIAN/preinst
    chmod +x DEBIAN/preinst
    echo "[Packaging Debian Package]"
    echo "[* Need root privilege, type your password *]"
    sudo chown -R root:wheel .
    cd ..
    "$DPKGLOC" -bZ lzma _install "tmp.deb"
    mv -f tmp.deb ../$DEBNAME"_iphoneos-arm.deb"
    sudo chown -R 501:20 _install
    cd ..
    echo "[${DEBNAME}_iphoneos-arm.deb packaged successfully]"
fi

echo "[All done]"
