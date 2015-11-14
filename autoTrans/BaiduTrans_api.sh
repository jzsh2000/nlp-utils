#!/usr/bin/env bash

# Author  : JIN Xiaoyang
# Date    : 2015-05-02
# Function: translate a file using baidu-fanyi API

# Example :
## ./BaiduTrans_api.sh -h
## echo 'Hello, world!' | ./BaiduTrans_api.sh -
## ./BaiduTrans_api.sh in.txt > out.txt
## ./BaiduTrans_api.sh -f en -t zh -s in.txt > out.txt

# Depends : curl grep coreutils
## curl 7.26.0
## grep (GNU grep) 2.12
## GNU coreutils 8.13 (cat ls rm sleep split)

# Refer   : 
## http://developer.baidu.com/wiki/index.php?title=%E5%B8%AE%E5%8A%A9%E6%96%87%E6%A1%A3%E9%A6%96%E9%A1%B5/%E7%99%BE%E5%BA%A6%E7%BF%BB%E8%AF%91/%E7%BF%BB%E8%AF%91API

##################################################

# These two scripts are found in 'moses' package, with some change
replace_unicode_punctuation="${0%/*}/../normalize/replace-unicode-punctuation.perl"
normalize_punctuation="${0%/*}/../normalize/normalize-punctuation.perl"

api_key_file="${0%/*}/api-key"
base_url="http://openapi.baidu.com/public/2.0/bmt/translate"
lang_in="auto"
lang_out="auto"
threads=1
norm=0

if [ -s $api_key_file ]; then
    # FILE exists and has a size greater than zero
    api_key=$(cat $api_key_file)
else
    touch $api_key_file
    echo "Please write API key to file '$api_key_file'" >&2
    exit 1
fi

# It's recommented that the translation query less than 3K characters
# in POST request. If GET request be used, less than 1K.
char_limit=3000
tmp_head=".tmp.$$."

##################################################
# change-log:
# version_1.0
#	Use baidu-fanyi api (updated from BaiduTrans.sh).
# version_1.1
#	Fix bug: if FILE contains a space, the script cannot read the file.
#	Fix bug: if the result contains quotes ("), it may be truncated.
#	Add function: this script can read stdin now.
#	Fix bug: the slashes (/) in result might be changed to '\/'.
##################################################

usage()
{
    echo "Usage: $0 [OPTION]... [FILE]"
    echo "Translate FILE, or stdin, to stdout."
    echo "If read from FILE, empty lines would be skipped."
    echo
    echo "  -f	LANG_IN:  source language (default: auto)"
    echo "  -t	LANG_OUT: target language (default: auto)"
    echo "  -m	CHAR_LIMIT: char limit in post request (default: 3000)"
    echo "  -n	THREADS:  number of threads run in parallel (default: 1)"
    echo "  -s	normalize punctuations"
    echo
    echo "  -h	display this message and exit"
    echo "  -v	output version information and exit"
    echo
    echo "When FILE is -, read standard input."
    echo "By default, selects -f auto -t auto -n1."

}

while getopts :f:t:m:n:shv OPT
do
    case "$OPT" in
	"f")
	    lang_in=$OPTARG;;
	"t")
	    lang_out=$OPTARG;;
	"m")
	    char_limit=$OPTARG;;
	"n")
	    threads=$OPTARG
	    # number of threads must be positive
	    if [ $threads -le 0 ];then
		threads=1
	    fi;;
	"s")
	    if [ -x $replace_unicode_punctuation ]&&[ -x $normalize_punctuation ]; then
		norm=1
	    else
		echo "$0: option -s invalid, please check files below:" >&2
		echo "	$replace_unicode_punctuation" >&2
		echo "	$normalize_punctuation" >&2
		exit 1
	    fi;;
	"h")
	    usage
	    exit 0;;
	"v")
	    echo "$0: v1.1 <-> 2015-05-06" >&2
	    exit 0;;
	":")
	    echo "$0: must supply an argument to -$OPTARG" >&2
	    echo "Try '$0 -h' for more information." >&2
	    exit 1;;
	"?")
	    echo "$0: illegal option -- '$OPTARG'" >&2
	    echo "Try '$0 -h' for more information." >&2
	    exit 1;;
    esac
done

if [ $# -gt 1 ]; then
    # leave the last argument, should be a filename
    shift $[$#-1]
fi

if [ "$1" == "-" ]; then
    # if read from stdin, set $threads to 0
    threads=0
elif [ ! -f "$1" ]; then
    echo "$0: cannot read file: $1" >&2
    echo "Try '$0 -h' for more information." >&2
    exit 1
else
    file=$1
fi

translate_term()
{
    local sub_term="$*"
    local result=""

    # use `curl` to invoke transtion engine, POST request used
    # baidu-translater returns json format, use grep/sed/awk may not be the best way
    while [ -n "$sub_term" ]
    do
	result=`curl -s --data-ascii client_id=$api_key --data-urlencode q="$sub_term" --data-ascii from=$lang_in --data-ascii to=$lang_out $base_url | grep -oP '(?<="dst":").*?(?="})'`
	[ -z "$result" ] && sleep 3 || break
    done

    result=${result//\\\"/\"}
    result=${result//\\\//\/}

    if [ $norm -eq 0 ]; then
	echo -e "$result"
    else
	# normalize punctuations
	echo -e "$result" | $replace_unicode_punctuation | $normalize_punctuation
    fi
}

translate_file()
{
    local sub_file="$1"
    local term=""

    IFS_old=$IFS
    IFS=$'\n'

    for line in `cat $sub_file`
    do
	term=`echo -e "$term\n$line"`
	# echo ${#term} >&2

	if [ ${#term} -gt $char_limit ]; then
	    translate_term "$term"
	    term=""
	fi
    done

    if [ -n "$term" ]; then
	translate_term "$term"
    fi

    IFS=$IFS_old
}

if [ $threads -eq 0 ]; then
    # read from standard input, notice it would be much slower
    while read term
    do
	translate_term "$term"
    done
elif [ $threads -eq 1 ];then
    # single-threaded
    translate_file "$file"
else
    # multi-threaded
    export base_url api_key lang_in lang_out norm char_limit
    rm -f ${tmp_head}in.*
    split -n l/$threads -d "$file" ${tmp_head}in.

    for sub_file in `ls ${tmp_head}in.*`
    do
	translate_file $sub_file > ${sub_file/in/out} &
    done
    wait

    cat ${tmp_head}out.*
    rm ${tmp_head}in.* ${tmp_head}out.*
fi
