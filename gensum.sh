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
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
TMPDIR=/tmp/genchecksum
version="1.5"
date="(02/04/2015)"
# For text colour
readonly RED="\033[01;31m"
readonly GREEN="\033[01;32m"
readonly BLUE="\033[01;34m"
readonly YELLOW="\033[00;33m"
readonly BOLD="\033[01m"
readonly FINE="\033[0m"

#Prints a spacer. If an argument is provided, it will be printed as the
# spacer "title", like "==> TITLE <=="
spacer() {
        if [ "$#" == "0" ]; then
                echo -e $GREEN"=========================================================="$FINE
        fi
        if [ "$#" -gt "0" ]; then
                strn="$1"
                for st in ${@:2:$#}; do
                strn="$strn $st"
                done
                echo -e $YELLOW"=========================================================="$FINE
                tput cuu 1
                printf %b $YELLOW"==> $FINE$BOLD$strn $FINE"$YELLOW"<\n"$FINE
        fi
}

#Generates a checksum for a file or a string. You can specify the program as first argument.
#Second argument is the file/ string of which we want to generate the digest
#the third argument is the index of the entry.
#If necessary compares the generated checksum with a list of checksums given as file.
comparesum() {
    printf %b $BLUE"$3) "$FINE$BOLD"$(echo "$1" | sed 's/sum//'): "$FINE
    case "$1" in
        "cksum") local parms='{print$1,$2}'
        ;;
        *)
        local parms='{print$1}'
        ;;
    esac
    if ! test -v STR; then
        local csum=$($1 $2 | awk $parms)
    else
        local csum=$(echo -n "$2" | $1 | awk $parms)
    fi
    if test -v CHKSUMS; then
        (grep $csum $CHKSUMS) > /dev/null
        if [ "$?" == "0" ]; then
            csum="$csum OK!"
            printf %b $GREEN
        else
            csum="$csum ERRATO!"
            printf %b $RED
        fi
    else
        printf %b $BOLD
    fi
    printf %b $csum$FINE"\n"
}

#Calculates checksum for given argument. The argument must be a file.
checksum() {
        spacer $1
        local r=1
        if test -v MD5 ; then
                comparesum md5sum $1 $r
                r=$(($r+1))
        fi
        if test -v SHA ; then
                if [ "$SHA" == "basic" ] || [ "$SHA" == "1" ] || [ "$SHA" == "all" ]; then
                        comparesum sha1sum $1 $r
                        r=$(($r+1))
                fi
                if [ "$SHA" == "all" ] || [ "$SHA" == "224" ]; then
                        comparesum sha224sum $1 $r
                        r=$(($r+1))
                fi
                if [ "$SHA" == "basic" ] || [ "$SHA" == "256" ] || [ "$SHA" == "all" ] ; then
                        comparesum sha256sum $1 $r
                        r=$(($r+1))
                fi
                if  [ "$SHA" == "all" ] || [ "$SHA" == "384" ]; then
                        comparesum sha384sum $1 $r
                        r=$(($r+1))
                fi
                if [ "$SHA" == "all" ] || [ "$SHA" == "512" ]; then
                        comparesum sha512sum $1 $r
                        r=$(($r+1))
                fi
        fi

		if test -v CK ; then
                #csum=$(cksum $1 |awk '{print$1,$2}')
                #echo -e "$BLUE$r)$FINE "$BOLD"CRC:$FINE $csum"
                comparesum cksum $1 $r
                r=$(($r+1))
		fi
        spacer
}

#Asks user if he wants to delete temporary files generated by this script.
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

#Custom exit function, it integrates ask_del for managing script created
#files and folders.
_exit() {
    IFS=$SAVEIFS
    if [[ -d $TMPDIR ]]; then
            ask_del 2>/dev/null
    fi
    exit $1
}

#Checks if the file given as argument is an elegible archive.
is_archive() {
    (file "$1" | grep 'compressed\|archive') > /dev/null
    return $?
}

#Recursive function for calculating checksums. It starts checking for archives
#then for directories and then if the argument is a simple file it will
#calculate its checksum.
checksum_cascade() {
        if 	is_archive $1; then
                archive $1
        elif [[ -d $1 ]]; then
                for file in $1/*; do
                        checksum_cascade $file
                done
        else
                checksum $1
        fi
}

#Extracts the archive given as argument and calls the recursive checksum
#function on its contents.
archive() {
        if 	is_archive $1
        then
                if ! [[ -d $TMPDIR ]] ; then
                        mkdir $TMPDIR
                fi
                FPATH=$(unar -q -r -o $TMPDIR $1 | grep 'extracted\ to' | awk -F \" '{print$2}')
                checksum $1 2>/dev/null
                checksum_cascade $FPATH
        else
            echo $1 " is not an archive."
            spacer
        fi
}

#Usage screen.
help() {
        echo -e "gensum $YELLOW$BOLD$version$FINE$YELLOW$BOLD$date$FINE, powerful multi file, multi checksum generator."
        echo "Copyright(C) 2015 sten_gun, Nhoya"
        echo ""
        echo -e $BOLD"  Usage: $0 [OPTIONS] [ARGS ... ]"$FINE
	echo ""
	echo -e $GREEN"======================================================================================"$FINE
        echo "  Available Options:"
        echo "    -m              		        Uses MD5 checksum"
        echo "    -s [1| 224| 256| 384| 512 |all]	Uses SHA1|SHA224|SHA256|SHA384|SHA512 or all."
	echo "    -c <checfile> <file>		Specifies a file for checksum check"
        echo "    -k                        		Uses CRC checksum"
        echo "    -d <directory>            		Calculate checksum for files inside a directory."
        echo "    -z <archive>              		Calculate checksum for an archive and its contents."
        echo "    -t <string>                	 	Calculate checksum for strings instead of files."
        echo "    -v                        		Display script version"
        echo "    -h                        		Display this page"
	echo -e $GREEN"======================================================================================"$FINE
}

#==== Main logic functions ====
#Argument parser.
argsparser() {
    urlregex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    p=0 #counter of checksum_cascade.
    if [ "$#" == "0" ]
        then help
    fi
    while getopts ":z:d:s:mhvtkc:" opt; do
            case "$opt" in
                h)  help
                    _exit 0
                ;;
                c) 
                    if [[ $OPTARG =~ $urlregex ]]; then
                        if ! [ -d $TMPDIR ]; then
                            mkdir $TMPDIR
                        fi
                        wget $OPTARG -O $TMPDIR/tmpsum -q --show-progress
                        tput cuu 1
                        tput el
                        OPTARG=$TMPDIR/tmpsum
                    fi
                    (file $OPTARG | grep "ASCII\ text") > /dev/null
                    if [ "$?" == "0" ]; then
                        CHKSUMS=$OPTARG
                    else
                        echo -e $RED"-$opt: $OPTARG is not a text file."$FINE
                        _exit 0
                    fi
                ;;
                s)
                    case "$OPTARG" in
                    1|224|256|384|512|"all")
                        SHA="$OPTARG"
                    ;;
               		*)
                	echo -e $RED"-s argument is wrong! accepted args: [1| 224| 256| 384| 512 |all]"$FINE
                	_exit 1
                    ;;
                    esac
                ;;
                m) MD5=1
                unset STR
                ;;
                k) CK=1
                ;;
                t) 
                    for str in ${@:$OPTIND}; do
                            STR="$STR $str"
                    done
                    if [ -v STR ]; then
                            echo -e $BOLD"String Checksum"$FINE
                            spacer
                            STR=$(echo -e "$STR" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                    else
                            echo -e $RED"Error: empty string"$FINE
                            _exit 1
                    fi
                    break
                ;;
                :) echo -e $RED"-$OPTARG parameter is mandatory."$FINE
                    _exit 1
                ;;
                v) echo $version$ $date
                    _exit 0
                ;;
            esac
    done

    if ! [ -v SHA ] && ! [ -v MD5 ]  && ! [ -v CK ]; then
            SHA="basic"
            MD5=1
            CK=1
    fi
    if ! test -z $STR ; then
        return
    fi
    OPTIND=1
    while getopts "z:d:s:mhvtkc:" opt; do
        case "$opt" in
          z) if is_archive $OPTARG; then
                echo -e $BOLD"Checking archive $OPTARG"$FINE
                p=1
                spacer
                checksum_cascade $OPTARG
            else
                echo -e $RED"-z: $OPTARG is not an archive file."$FINE
                _exit 1
            fi
          ;;
          d) if [[ -d $OPTARG ]]; then
                echo -e $BOLD"Checking directory $OPTARG"$FINE
                p=1
                spacer
                checksum_cascade $OPTARG
            else
                echo -e $RED"-d: $OPTARG is not a directory."$FINE
                _exit 1
            fi
          ;;
          \?) echo -e $RED"invalid option(s): -$OPTARG"$FINE
              _exit 1
          ;;
          :) echo -e $RED"-$OPTARG needs argument(s)"$FINE
             _exit 1
          ;;
        esac
done
}

#Main logic
main(){
    if test -v STR; then
        checksum "$STR"
        _exit 0
    else
        r=0
        for file in ${@:$OPTIND}; do
            if [ $r == 0 ] ; then
                    echo -e $BOLD"Checking given files"$FINE
                    spacer
                    r=$(($r+1))
            fi
            if [ -d $file ]; then
                    echo -e $RED"$file is a directory, skipping."$FINE
                    spacer
            elif [ -e $file ]; then
                    checksum $file
            else
                    echo -e $RED"$file: file  doesn't exist"$FINE
                    spacer
            fi
        done
    fi
    if [ "$r" == "0" ] && [ "$p" == "0" ]; then
        echo -e $RED"Error: missing arguments."$FINE
        _exit 1
    fi
}
#---------------------------------------------------- Script Start

argsparser $@
main $@
_exit 0

