#!/bin/bash
#
# v 0.0.1 - Geoff Maciolek - 2015-04-11
#
# This is a support script to help manage your spam/notspam/okmail/discarded collections
# in ASSP, the Anti-Spam SMTP Proxy.  It is likely to be easily adaptable to other systems
# with minor changes to the "case" statement directories.
#
# The tool provides an interactive message view to help you file messages correctly; for
# example, via "searchsort.sh okmail" you can verify that messages in  "okmail" are actually
# not spam, then file them individually to "notspam" to contribute to the bayesian database.
# Messages that were in fact spam can be flagged to the "errors/spam" directory
#
# Additionally, you can specify a search string/strings, to search for mail matching given
# patterns.  You can use the grep -E syntax, ala "searchsort.sh spam 'domain1.com|what.net'"
#
# TODO:
#
# * Something better than the gross Pause()
# * Improvehighlighting
# * Modularize the config
# * Search both 'discarded' & 'spam' or 'notspam' & 'okmail' at once
# * Port to an actual language
#
# Issues:
#
# * On certian messages with long lines, the preview scrolling is broken - hit "u" to
#     scroll up as a workaround
#
##########################################


Pause() # Seriously this was the best I could do at the time.
{
    key=""
    echo -n Hit any key to continue....
    stty -icanon
    key=`dd count=1 2>/dev/null`
    stty icanon
}


# Values for vaarious things, some unused
step=10
skip=0
COUNT=1
numbertoprocess=200


# Choose the program operation mode - what directory do we process?

case "$1" in
  "okmail")
    from="okmail";
    ifspam="errors/spam";
    ifnotspam="notspam";
     ;;
  "discarded")
    from="discarded";
    ifspam="spam";
    ifnotspam="errors/notspam";
     ;;
  "spam")
    from="spam";
    ifspam="spam";
    ifnotspam="errors/notspam";
     ;;
  "notspam")
    from="notspam";
    ifspam="errors/spam";
    ifnotspam="notspam";
     ;;
   *)
     echo "ASSP Bayesian Spam Database sorting tool.  Use this tool to manage the unfiltered"
     echo "(or filtered) directories of collected e-mail, and file into appropriate locations"
     echo "based on user input.  This tool will help improve the spam scanning by taking messages"
     echo "not currently weighted for use in the spam database."
     echo
     echo "This tool MUST be run from your ASSP folder; it doesn't check for this."
     echo
     echo "Syntax: ";
     echo
     echo "$0 okmail - Scan the \"okmail\" directory and process according to user input."
     echo "$0 discarded  - Scan the \"discarded\" directory and process according to user input."
     echo "$0 spam  - Scan the \"spam\" directory and process according to user input."
     echo "$0 notspam  - Scan the \"notspam\" directory and process according to user input."
     echo
     echo "$0 ... \"search string\" - Scan the ... directory for files containing \"search string\""
     echo "       This uses the egrep/grep -E syntax. The string  \"domain1|user2\" will match both"
     echo
     exit
   ;;
esac

searchstring=$2

if [[ -z $searchstring ]]
   then
      messagelist=$(find $from/ -type f -printf "%T+ %p\n"|sort -r|cut -d' ' -f2|head -n $numbertoprocess)
   else
      messagelist=$(find $from/ -type f -printf "%T+ %p\n"|sort -r|cut -d' ' -f2|xargs grep -l "${searchstring}"|head -n $numbertoprocess)
fi

#set up stdin as a new file descriptor
exec {infd}<&0

while IFS= read -r msg;do
#while [[ 0 = 1 ]]; do
  NEXT=0
  offset=0
  while [ $NEXT -eq 0 ]; do

# echo "Message: $msg"
#Pause

    termlines=$(tput lines)
    lines=$((${termlines} - 5))  # Leave room for the interface and unusually long lines.
    clear
    echo -e "   Message $COUNT \033[1m $msg \033[0m ***"
    echo "---------------------------------------------------------------------------------"

    # Display message, includes some highlighting
    head -n $((lines + offset)) -- $msg | tail -n $lines | perl -pe 's/.*\b(Subject|To|From|Intended-For)\b.*/\e[1;33;40m$&\e[0m/g; s/.*\b(Assp|assp|Bayes|bayes)\b.*/\e[1;34;40m$&\e[0m/g'
#  head -n 40 "$msg"
    echo "-----------------------------------"
    echo -e "\033[1m  [s]pam [n]otspam [*/i]gnore [d]own/[u]p [e]xamine | [q]uit\033[0m"

#    read -n 1 resp
# use new file descriptor
   read -n1 <&$infd resp
    case "$resp" in
 	"s")
	   #echo "Spam - moving to $ifspam";
	   mv -v -- $msg $ifspam
	   COUNT=$((COUNT + 1));
	   NEXT=1;
	;;
 	"n")
	   #echo "Legit Mail - moving to $ifnotspam";
	   mv -v -- $msg $ifnotspam
           COUNT=$((COUNT + 1));
	   NEXT=1;
	;;
	"e")
	  less -- $msg
	  echo "That was - $msg";
	  Pause;
	;;
	"d")
	  offset=$((offset + step));
	;;
	"u")
	  offset=$((offset - step));
	;;
#	"k")
#          skip=50;
#	;;
	"q")
	   echo
	   echo "Exiting..."
	   echo
	#close the file descriptor
	exec {infd}<&-
	   exit;
	;;
	*)
#	  echo -e "You pressed $resp";
#	  echo "Ignore";
#	  sleep 5;
          COUNT=$((COUNT + 1));
	  NEXT=1;
	;;
   esac

  done

done <<< "$messagelist"


#close the file descriptor
exec {infd}<&-
