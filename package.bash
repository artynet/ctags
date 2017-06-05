#!/bin/bash -x
# Copyright (c) 2014-2016 Arduino LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

OUTPUT_VERSION=5.8-arduino11

# initial clean
rm -rf distrib/

cd ctags-arduino/

#linux 64
make distclean
mkdir -p ../distrib/linux64
./configure
make -j2
cp ctags ../distrib/linux64

#linux 32
make distclean
mkdir -p ../distrib/linux32
CC="gcc -m32" ./configure
make -j2
cp ctags ../distrib/linux32

# arm
make distclean
mkdir -p ../distrib/arm
./configure --host=arm-linux-gnueabihf
make -j2
cp ctags ../distrib/arm

# mips-linux-uclibc
make distclean
mkdir -p ../distrib/mips-uclibc
export STAGING_DIR=/opt/toolchain-48-1505
export PATH=/opt/toolchain-48-1505/bin:$PATH
./configure --host=mips-openwrt-linux-uclibc
make -j2
cp ctags ../distrib/mips-uclibc

# osx
make distclean
mkdir -p ../distrib/osx
platform=$(o64-clang -v 2>&1 | grep Target | awk {'print $2'} | sed 's/[.].*//g')
CC="o64-clang" ./configure --host=$platform
make -j2
cp ctags ../distrib/osx

# windows
make distclean
patch -p1 < ../patches-mingw/001-fix-unused-attribute.patch
mkdir -p ../distrib/windows
./configure --host=i686-w64-mingw32 --disable-external-sort
make -j2
cp ctags.exe ../distrib/windows

# final clean
make distclean
git checkout .

cd ../

package_index=`cat package_index.template | sed s/%%VERSION%%/${OUTPUT_VERSION}/`

cd distrib/

rm -f *.bz2

folders=`ls`
t_os_arr=($folders)

for t_os in "${t_os_arr[@]}"
do
	FILENAME=ctags-arduino-${OUTPUT_VERSION}-${t_os}.tar.bz2
	tar -cjvf ${FILENAME} ${t_os}/*
	SIZE=`stat --printf="%s" ${FILENAME}`
	SHASUM=`sha256sum ${FILENAME} | cut -f1 -d" "`
	T_OS=`echo ${t_os} | awk '{print toupper($0)}'`
	echo $T_OS
	package_index=`echo $package_index |
		sed s/%%FILENAME_${T_OS}%%/${FILENAME}/ |
		sed s/%%FILENAME_${T_OS}%%/${FILENAME}/ |
		sed s/%%SIZE_${T_OS}%%/${SIZE}/ |
		sed s/%%SHA_${T_OS}%%/${SHASUM}/`
done
cd -

set +x

echo ================== CUT ME HERE =====================

echo ${package_index} | python -m json.tool
