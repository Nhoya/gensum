#!/bin/bash
#
#		Copyright (C) 2015 sten_gun, Nhoya.
#
#   gensum is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>

TMPDIR=/tmp/genchecksum
version="1.3 (3/23/15)"
# For text colour
readonly RED="\033[01;31m"
readonly GREEN="\033[01;32m"
readonly BLUE="\033[01;34m"
readonly YELLOW="\033[00;33m"
readonly BOLD="\033[01m"
readonly FINE="\033[0m"

checksum() {
    local r=1
    if test -v MD5 ; then
       echo -e "$BLUE$r)$FINE "$BOLD"md5:$FINE $(md5sum $1 )"
       r=$(($r+1))
    fi
    if test -v SHA ; then
        if [ "$SHA" == "all" ] || [ "$SHA" == "1" ]; then
            echo -e "$BLUE$r)$FINE "$BOLD"sha1:$FINE  $(sha1sum $1)"
            r=$(($r+1))
        fi
        if [ "$SHA" == "all" ] || [ "$SHA" == "256" ]; then
            echo -e "$BLUE$r)$FINE "$BOLD"sha256:$FINE $(sha256sum  $1)"
            r=$(($r+1))
        fi
	fi
	if test -v CK ; then
		echo -e "$BLUE$r)$FINE "$BOLD"CRC:$FINE $(cksum $1 )"
        r=$(($r+1))
	fi
    echo -e $GREEN"=========================================================="$FINE
}

string_sum() {
    local r=1
	if test -v MD5 ; then
            echo -e "$BLUE$r)$FINE "$BOLD"md5:$FINE $(echo -n "$1" | md5sum )"
            r=$(($r+1))
        fi
        if test -v SHA ; then
            if [ "$SHA" == "all" ] || [ "$SHA" == "1" ]; then
                echo -e "$BLUE$r)$FINE "$BOLD"sha1:$FINE  $(echo -n "$1" | sha1sum)"
                r=$(($r+1))
            fi
            if [ "$SHA" == "all" ] || [ "$SHA" == "256" ]; then
                echo -e "$BLUE$r)$FINE "$BOLD"sha256:$FINE $(echo -n "$1" | sha256sum)"
                r=$(($r+1))
            fi
        fi
        echo -e $GREEN"==========================================================="$FINE
}

ask_del() {
        echo -e $BOLD"Delete extracted files? ($TMPDIR) [y/n]"$FINE
read input
case $input in
        ""| [Yy]) rm -rf $TMPDIR
        echo -e $RED"Files deleted"$FINE
        ;;
        *) echo -e  $YELLOW"Warning: temporary files saved in $TMPDIR"$FINE
        ;;
esac
}

checksum_cascade() {
    if 	(file $1 |awk -F . '{print$NF}' |grep 'zip\|rar\|7z\|tar\|gz\|bz'); then
        archive $1
	elif [[ -d $1 ]]; then
        for file in $1/*; do
            checksum_cascade $file
        done
    else
        checksum $1
    fi
}

archive() {
if 	(file $1 |awk -F . '{print$NF}' |grep 'zip\|rar\|7z\|tar\|gz\|bz')
then
	mkdir $TMPDIR
	unar -o $TMPDIR $1
    checksum $1 2>/dev/null
	checksum_cascade $TMPDIR
	ask_del 2>/dev/null
fi
}

help() {
	echo "gensum $version, powerful multi file, multi checksum generator."
	echo "Copyright(C) 2015 sten_gun, Nhoya"
	echo ""
	echo "  Usage: $0 [OPTIONS] [ARGS ... ]"
	echo ""
	echo "  Available Options:"
	echo "    -m                        Uses MD5 checksum"
	echo "    -s [1|256|all]            Uses SHA1|SHA256 or both checksums"
	echo "    -k                        Uses CRC checksum"
	echo "    -d <directory>            Calculate checksum for each file in a directory"
	echo "    -z <archive>              Calculate checksum for archive and each file in it"
	echo "    -t                        Calculate checksum for strings instead of files (put string as arg)"
	echo "    -v                        Display script version"
	echo "    -h                        Display this page"
}
#---------------------------------------------------- Script Start

while getopts ":z:d:as:mhvtk" opt; do
    case "$opt" in
        h)  help
            exit 0
        ;;
        s) SHA="$OPTARG"
        ;;
        m) MD5=1
        ;;
	    k) CK=1
	    ;;
        t) STR=1
        ;;
        :) echo -e $RED"-$OPTARG parameter is mandatory: [256| 1 |all]"$FINE
        ;;
	v) echo $version
		exit 0
	;;
    esac
done

if ! [ -v SHA ] && ! [ -v MD5 ]  && ! [ -v CK ]; then
    SHA="all"
    MD5=1
    CK=1
fi

OPTIND=1
while getopts ":z:d:as:mhvtk" opt; do
    case "$opt" in
      z) echo -e $BOLD"Checking archive $OPTARG"$FINE
      echo -e $GREEN"==========================================================="$FINE
      archive $OPTARG
      ;;
      d) echo -e $BOLD"Checking directory $OPTARG"$FINE
      echo -e $GREEN"==========================================================="$FINE
      checksum_cascade $OPTARG
      ;;
      \?) echo -e $RED"invalid option(s): -$OPTARG"$FINE
          exit 1
      ;;
      :) echo -e $RED"-$OPTARG needs argument(s)"$FINE
         exit 1
      ;;
    esac
done

if test -v STR; then
    for str in ${@:$OPTIND}; do
        strings="$strings $str"
    done
    if [ -v strings ]; then
        echo -e $BOLD"String Checksum"$FINE
        strings=$(echo -e "$strings" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        echo -e $YELLOW"==> "$FINE$GREEN$strings$FINE
        string_sum "$strings"
    else
        echo -e $RED"Error: empty string"$FINE
        exit 1
    fi
    exit 0
fi

r=0
for file in ${@:$OPTIND}; do
    if [ $r == 0 ] ; then
    echo -e $BOLD"Checking given files"$FINE
    echo -e $GREEN"==========================================================="$FINE
    r=$(($r+1))
    fi
    if [ -d $file ]; then
        continue
    fi
    if [ -e $file ]; then
        checksum $file
    else
        echo -e $ROSSO"$file: file  doesn't exist"$FINE
    fi
done

exit 0
