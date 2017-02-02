#!/bin/bash
# This shouldn't be used just yet, I plan on rewriting a large portion of this script at some point
#Well...
version=0.8
author="DecentM"
 
#Set color commands
cred="$(tput setaf 1)"
cgreen="$(tput setaf 2)"
clblue="$(tput setaf 12)"
clred="$(tput setaf 9)"
cbold="$(tput bold)"
creset="$(tput sgr0)"
 
#Reset color
tput sgr0
 
#Get distro name, and put it in $os
os="$(cat /etc/*-release | head -1 | cut -d "=" -f2 | cut -d " " -f1)"
 
#Import ui language selection from arguement #1
uilang="$1"
 
#If help was requested, print it, then quit
if [ "$1" == "help" ]; then
    echo "$(echo ${0###*/} | cut -d "/" -f-) "v$version" by $author"
    echo "The goal of this script is to list incorrect ssh logins on linux boxes by users."
    echo "Usage: ${0} [<language>/help]"
    echo
    exit
fi
 
#Set ui language to Hungarian if $uilang is "hu"
if [ "$uilang" == "hu" ]; then
    uirank='Helyzet'
    uitries='Próbák'
    uiuname='Felhasználónév'
    uivalidusers='A fentiek közül létező felhasználók:'
    uitotal='összesen'
    uilasthack='Legutóbbi sikertelen próbálkozás'
    uilastcalled='legutóbb ekkor futott le:'
    uioserr='A disztribúciód jelenleg nem támogatott. Ha szeretnéd, módosítsd a szkriptet, hogy támogassa a azt!'
    uitotalfails='Hibás bejelentkezések száma összesen:'
    uiwhen='ekkor:'
    uiuser='felhasználó:'
    uiip='erről a címről:'
     
fi
 
#Set ui language to Engligh if $uilang is "en"
if [ "$uilang" == "en" ]; then
    uirank='Rank'
    uitries='Tries'
    uiuname='Username'
    uivalidusers='Valid users:'
    uitotal='total'
    uilasthack='Last failed login attempt'
    uilastcalled='has been last run at:'
    uioserr='Your distribution is currently not supported. Feel free to modify this script to add your distro!'
    uitotalfails='Total failed logins:'
    uiwhen='at'
    uiuser='user'
    uiip='from'
fi
 
#If $uirank is empty, that means no/incorrect language was specified. If so, print English help, then quit
if [ "$uirank" == "" ]; then
    echo "Incorrect, or empty language selection. Please execute ${0} help for more information"
    exit
fi
 
#Set path and offsets for Ubuntu, if it was detected
if [ "$os" == "Ubuntu" ]; then
    log="cat /var/log/auth.log"
    logfiltertime="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | sed 's/ //' | cut -d " " -f1-3)"
    logfilteruser="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | sed 's/ //' | cut -d " " -f9)"
    logfilterip="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | sed 's/ //' | cut -d " " -f11)"
fi
 
#Set path and offsets for Fedora if it was detected
if [ "$os" == "Fedora" ]; then
    log="journalctl -u sshd"
    logfiltertime="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | cut -d ' ' -f1-3)"
    logfilteruser="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | cut -d ' ' -f9)"
    logfilterip="$($log | grep -i 'Failed password for' | sed '/message repeated/d' | tail -1 | cut -d ' ' -f11)"
fi
 
#If at this point $log is empty, that means no/incorrect destro was detected. If so, print help, then quit
if [ "$log" == "" ]; then
    echo "$uioserr"
    exit
fi
 
#Now comes the messy stuff, brace youself!
#First, we print all attempted user logins' usernames
 
#List, filter, format, sort, add numbers, uniq and colorize the output of $log
$log | grep -i 'Failed password for' | sed 's/^.*Failed/Failed/' | sed '/^$/d' | cut -c21- | sed 's/from.*//' | sed 's/\(^invalid\)\(.*\)/\2 \1/' | sed -e 's/user //' | sed 's/ *//' | sed 's/$/#!/' | sed 's/invalid#!/-/g' | sort | uniq -c | sort -b -f -h -r | cat -n | sort -b -f -h -r | egrep --color=always '#!|^'
 
#Print legend
echo "--------------------------------"
echo "$uirank   $uitries    $uiuname"
echo
 
#Second, we print a list of users, that got 'hit'. Note: the attempt still failed, but watch out for these accounts, as they most likely are common.
#But before that, we count how many users tried to login by printing the last row's first column.
echo "$uivalidusers ($($log|grep -i 'Failed password for' | sed 's/^.*Failed/Failed/' | sed 's/from.*//' | sort | uniq | cat -n | cut -d "  " -f1 | cut -c4- | tail -n 1 | tr -d " \t\r") $uitotal)"
 
#So we list, filter, format, sort, add numbers, uniq and filter once more to only show users that exist in the system.
$log | grep -i "Failed password for" | sed 's/^.*Failed/Failed/' | sed '/^$/d' | cut -c21- | sed 's/from.*//' | sed 's/\(^invalid\)\(.*\)/\2 \1/' | sed -e 's/user //' | sed 's/ *//' | sed 's/$/#!/' | sed 's/invalid#!/-/g' | sort | uniq -c | sort -b -f -h -r | cat -n | sort -b -f -h -r | grep --color=always "#!"
 
#And the legend once more
echo "--------------------------------"
echo "$uirank   $uitries    $uiuname"
echo
 
#Here, we display how many times anyone failed to log in, by printing the last row's first column, but without filtering this time.
echo "$uitotalfails $clred$($log | grep -i 'Failed password for' | sed '/message repeated/d' | cat -n | tail -1 | cut -c3- | cut -d "   " -f1) $creset"
 
#Print the datetime, user and IP from the last failed login attempt by doing a bunch of filtering and formatting to the last line that contains a failed login.
echo "$uilasthack $uiwhen $clred$logfiltertime $creset$uiuser $clred$logfilteruser $creset$uiip $clred$logfilterip $creset"
 
#Lastly, we print the current date/time in the Hungarian format in case the script is run by cron or something similar
echo "${0} $uilastcalled $cgreen$(date +%Y.%m.%d' ''('%A')',' '%H:%M:%S) $creset"

#I plan on making the list/format/filter stuff all work from within variables, and datetime display depend on language settings.
