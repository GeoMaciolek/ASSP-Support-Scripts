#!/bin/bash
# ASSP blockedmail searching tool v0.1
# Geoff Maciolek
# 2015-04-14 (older version), cleanup soon

if [[ -z $1 ]]
   then
        echo
        echo "ASSP Maillog search tool (by Geoff Maciolek)"
        echo
        echo "Usage:  $0 \"search string\" [days]"
        echo
        echo " \"days\" is optional, defaults to 3"
        echo
        echo "Examples:"
        echo "   $0 \"The Mail Subject\" 5 - searches for 5 days worth of logs"
        echo "   $0 \"username@domain\" - searches for 3 days worth of logs (default)"
        echo
        exit
fi

if [[ "" -eq $2 ]]
  then
    days="3"
  else
    days=$2
fi

#echo "Here are the last $days days of log files"

files=`find /usr/local/assp/logs/ -type f -name \*bmaillog.txt\* -mtime -${days}`
#files=`find /usr/local/assp/logs/ -type f -name \*.txt -mtime -${days}`
#zfiles=`find /usr/local/assp/logs/ -type f -name \*.txt.gz -mtime -${days}`


#echo  "Searching files..."
zgrep -iE $1 $files

#if [[ -n ${zfiles} ]]
#   then
#      echo "Searching compressed files..."
#echo      zgrep -ie $1 $zfiles
#    else
#      echo "No compressed files."
#fi

