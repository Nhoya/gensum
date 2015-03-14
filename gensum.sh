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
version="1.1 (3/14/15)"

checksum() {
        if test -v MD5 ; then
            echo "md5: $(md5sum $1 )"
        fi
        if test -v SHA ; then
            if [ "$SHA" == "all" ] || [ "$SHA" == "1" ]; then
                echo "sha1:  $(sha1sum $1)"
            fi
            if [ "$SHA" == "all" ] || [ "$SHA" == "256" ]; then
                echo "sha256: $(sha256sum  $1)"
            fi
        fi
        echo ""
}
string_sum() {
if test -v MD5 ; then
            echo "md5: $(echo -n "$1" | md5sum )"
        fi
        if test -v SHA ; then
            if [ "$SHA" == "all" ] || [ "$SHA" == "1" ]; then
                echo "sha1:  $(echo -n "$1" | sha1sum)"
            fi
            if [ "$SHA" == "all" ] || [ "$SHA" == "256" ]; then
                echo "sha256: $(echo -n "$1" | sha256sum)"
            fi
        fi
        echo ""
}

ask_del() {
        echo "Delete extracted files? ($TMPDIR) [y/n]"
read input
case $input in
        ""| [Yy]) rm -rf $TMPDIR
        echo -e "\e[31mFiles deleted\e[0m"
        ;;
        *) echo -e  "\e[31mWarning: temporary files saved in $TMPDIR\e[0m"
        ;;
esac
}

checksum_cascade() {
    if 	(file $1 |awk -F . '{print$NF}' |grep 'zip\|rar\|7z\|tar\|gz\|bz'); then
        archive $1
	elif [[ -d $1 ]]; then
        for file in "$1/*"; do
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
	echo "gensum 1.1 (3/14/2015), powerful checksums generator!"
	echo "Copyright(C) 2015 sten_gun, Nhoya"
	echo ""
	echo "Usage: gensum [options] [files]"
	echo ""
	echo "Available Options:"
	echo "-m 						Uses MD5 checksum."
	echo "-s [1|256|all] 			Uses SHA1|SHA256 or both checksums."
	echo "-d <directory> 			Calculate checksum for each file in a directory"
	echo "-z <archive> 				Calculate checksum for archive and each file in it"
	echo "-t <string>				Calculate checksum for string"
	echo "-v 						Display version"
	echo "-h 						Display this page"
}
#---------------------------------------------------- Script Start

while getopts ":as:mhv" opt; do
    case "$opt" in
        h)  help
            exit 0
        ;;
        s) SHA="$OPTARG"
        ;;
        m) MD5=1
        ;;
        :) echo "-$OPTARG need param: 256 / 1 / all"
        ;;
	v) echo $version
		exit 0
	;;
    esac
done

if ! [ -v SHA ] && ! [ -v MD5 ]; then
    SHA="all"
    MD5=1
fi

OPTIND=1
while getopts ":z:d:t:as:mhv" opt; do
    case "$opt" in
      z) echo "Checking archive $OPTARG"
      archive $OPTARG
      ;;
      d) echo "Checking directory $OPTARG"
      checksum_cascade $OPTARG
      ;;
      t) string_sum $OPTARG
      ;;
      \?) echo "invalid option(s): -$OPTARG"
          exit 1
      ;;
      :) echo "-$OPTARG needs argument(s)"
         exit 1
      ;;
    esac
done

echo "Checking given files"
for file in ${@:$OPTIND}; do
    if [ -e $file ]; then
        checksum $file
    else
        echo "$file: file  doesn't exist"
    fi
done

exit 0
