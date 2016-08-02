#!/bin/bash
# gitline - github api script

############################################################
# How To Use
############################################################

# add gitline_config.sh to:
# ~/gitline_config.sh

# this file containes 2 variables
# ----------------------------------------------------------
# TOKEN - your github security token
# GHUSER - your username on github
# ----------------------------------------------------------


# add the following aliases to your .bash_profile
# ----------------------------------------------------------
# alias gitline='/usr/local/bin/gitline.sh'
# alias gl='/usr/local/bin/gitline.sh'
# ----------------------------------------------------------


# in terminal:
# ----------------------------------------------------------
# gitline command args
# note: each command has notes on what arguments it takes
# ----------------------------------------------------------

############################################################

VERSION=0.1.0
SUBJECT=gitline
USAGE="gitline command issueNumber assignee_or_Label"

#github api
DOMAIN="https://api.github.com"

# holds per user config info
CONFIG_FILE=~/gitline_config.sh
CONFIG_FILE_BAK=~/gitline_config.sh.bak

# holds array
TEMP_FILE=~/gitline_temp.txt

# variables
whichMethod=$1
issueNumber=$2
assignee_or_label=$3

############################################################

# check to see if config file exists
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
else
  echo '
  ERROR: missing config.
  to create config run "gitline config :token :github_username"
  '
  # create files
  echo '# gitline config' >> $CONFIG_FILE
  echo '' >> $TEMP_FILE
  exit
fi

# set configurations
# usage:
# gitline config [token] [owner] [repo] [github username] [qa username]
# setToken=$2
# setOwner=$3
# setRepo=$4
# setGH_Username=$5
# setQA_Username=$6
function config() {
  cat $CONFIG_FILE > $CONFIG_FILE_BAK
  # set token
  if [ $setToken ]; then
    echo 'TOKEN='${setToken} >> $CONFIG_FILE
    echo 'added [token] to config'
  fi
  # set github organization/owner
  if [ $setOwner ]; then
    echo 'OWNER='${setOwner} >> $CONFIG_FILE
    echo 'added github [organization or owner] to config'
  fi
  # set github repo
  if [ $setRepo ]; then
    echo 'REPO='${setRepo} >> $CONFIG_FILE
    echo 'added github [repo] to config'
  fi
  # set github username
  if [ $setGH_Username ]; then
    echo 'GHUSER='${setGH_Username} >> $CONFIG_FILE
    echo 'added github [your username] to config'
  fi
  # set qa github username
  if [ $setQA_Username ]; then
    echo 'QAUSER='${setQA_Username} >> $CONFIG_FILE
    echo 'added github [qa person username] to config'
  fi
}

# usage
# listAssignees
# This call lists all the available assignees to which issues may be assigned. (repo)
function listAssignees() {
  listAssignees=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/assignees)
  echo "$listAssignees"
}
# usage
# listLables [issueNumber]
# List labels on an issue
function listLabels() {
  listLabels=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels)
  echo "$listLabels"
}

############################################################

# usage
# addAssignee [issueNumber] [assigneUsername]
# removeAssignee [issueNumber] [assigneUsername]
# add a single assignee to an issue
function addAssignee() {
  addAssignee=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/assignees -X POST -H "Content-Type: application/json" --data '{ "assignees":["'${assignee_or_label}'"]}')
  echo "$addAssignee"
}
# remove a single assignee to an issue
function removeAssignee() {
  removeAssignee=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/assignees -X DELETE -H "Content-Type: application/json" --data '{ "assignees":["'${assignee_or_label}'"]}')
  echo "$removeAssignee"
}

############################################################

# usage
# addLabel [issueNumber] [labelToApply]
# removeLabel [issueNumber] [labelToApply]
# add a label to an issue
function addLabel() {
  addLabel=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels -X POST -H "Content-Type: application/json" --data '["'${assignee_or_label}'"]')
  echo "$addLabel"
}
# remove a label from an issue
function removeLabel() {
  removeLabel=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels/${assignee_or_label} -X DELETE)
  echo "$removeLabel"
}

############################################################

# usage
# addComment [issueNumber] [commentContent]
# add a comment to an issue
function addComment() {
  addComment=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/comments -X POST -H "Content-Type: application/json" --data '{ "body":"'"$assignee_or_label"'"}')
  echo "$addComment"
}

############################################################

# send issue to QA
# usage
# toQA [issueNumber]
function toQA() {
  assignee_or_label="InReview"
  addLabel
  assignee_or_label="InProgress"
  removeLabel

  assignee_or_label=${GHUSER}
  removeAssignee
  assignee_or_label=${QAUSER}
  addAssignee
}

# add label InProgress to issue
# usage
# toInProgress [issueNumber]
function toInProgress() {
  assignee_or_label="InProgress"
  addLabel
}

############################################################

# gitline add and commit with a message
# 1 - command
# 2 - issue number
# 3 - comment

#  git add -A && git commit -m
function ac() {
  echo ${assignee_or_label}
  git add -A && git commit -m "${assignee_or_label} #${issueNumber}"
  toInProgress
  addArray
}

############################################################

# add issue number to an array
function addArray() {
  echo "add single issue to array"
  echo "${issueNumber}" >> $TEMP_FILE
  status
}
# remove issue number from temp file
function removeArray() {
  echo "remove single issue from array"
  sed -i '' 's/'${issueNumber}'//g' $TEMP_FILE
  status
}
# clear that array
function clearArray() {
  > $TEMP_FILE
  echo $issueNumber
}

# echo issue numbers in temp file
function status() {
  cat $TEMP_FILE
}

# loop through each issue number in the array and send it [toQA]
function loopQA() {
  while read p; do
    echo $p
    issueNumber=$p
    toQA
  done <$TEMP_FILE
  clearArray
}

############################################################



########################################################################################################################
########################################################################################################################

############################################################
# help | documention
############################################################

function help() {

############################################################
if [ "$specificCommand" == "addLabel" ]; then
  echo '
  Description:
    -add a single label to a specific issue number

  Usage:
    gitline addLabel [Issue Number] [Label to remove]
  '
############################################################
elif [ "$specificCommand" == "removeLabel" ]; then
  echo '
  Description:
    -remove a single label from a specific issue number

  Usage:
    gitline removeLabel [Issue Number] [Label to remove]
  '
############################################################
elif [ "$specificCommand" == "addAssignee" ]; then
  echo '
  Description:
    -add an assignee to a specific issue number

  Usage:
    gitline addAssignee [Issue Number] [Assignee to add]
  '
############################################################
elif [ "$specificCommand" == "removeAssignee" ]; then
  echo '
  Description:
    -remove an assignee from a specific issue number

  Usage:
    gitline removeAssignee [Issue Number] [Assignee to remove]
  '
############################################################
elif [ "$specificCommand" == "listAssignees" ]; then
  echo '
  Description:
    -list all assignees availble to assigne in this repo

  Usage:
    gitline listAssignees
  '
############################################################
elif [ "$specificCommand" == "listLabels" ]; then
  echo '
  Description:
    -list all labels currently applied to a specific issue number

  Usage:
    gitline listLabels [Issue Number]
  '
############################################################
elif [ "$specificCommand" == "addComment" ]; then
  echo '
  Description:
    -add a comment to a specific issue number

  Usage:
    gitline addComment [Issue Number] ["Comment in quotes"]
  '
############################################################
elif [ "$specificCommand" == "toQA" ]; then
  echo '
  Description:
    -send a specific issue number to QA. this includes:
      removing "InProgress" label
      adding "InReview" label
      removing self as assignee
      adding qa user as assignee

  Usage:
    gitline toQA [Issue Number]
  '
############################################################
elif [ "$specificCommand" == "toInProgress" ]; then
  echo '
  Description:
    -add "InProgress" label to a specific issue number

  Usage:
    gitline toInProgress [Issue Number]
  '
############################################################
elif [ "$specificCommand" == "addArray" ]; then
  echo '
  Description:
    -add issue number to array for using later in loopQA

  Usage:
    gitline addArray [Issue Number]
  '
############################################################
elif [ "$specificCommand" == "removeArray" ]; then
  echo '
  Description:
    -remove issue number from array for using later in loopQA

  Usage:
    gitline removeArray [Issue Number]
  '
############################################################
elif [ "$specificCommand" == "status" ]; then
  echo '
  Description:
    -print all issue numbers currently in array

  Usage:
    gitline status
  '
############################################################
elif [ "$specificCommand" == "clearArray" ]; then
  echo '
  Description:
    -remove all issues from array

  Usage:
    gitline clearArray
  '
############################################################
elif [ "$specificCommand" == "loopQA" ]; then
  echo '
  Description:
    -loop through issue number array and send "toQA"
      run "gitline help toQA" for more information

  Usage:
    gitline loopQA
  '
############################################################
elif [ "$specificCommand" == "ac" ]; then
  echo '
  Description:
    -add and commit a message to git appended with an issue number.
    -send specific issue number "toInProgress"
      run "gitline help toInProgress" for more information

  Usage:
    gitline ac [Issue Number] ["Comment to commit on github in quotes"]
  '
############################################################
elif [ "$specificCommand" == "config" ]; then
  echo '
  Description:
    -add config settings to config file

  Usage:
    gitline config [token] [owner] [repo] [github username] [qa username]
  '
############################################################


############################################################
else
  echo '
  Commands:
    help
    config
    addLabel
    removeLabel
    addAssignee
    removeAssignee
    listAssignees
    listLabels
    addComment
    toQA
    toInProgress
    addArray
    removeArray
    status
    clearArray
    loopQA
    ac

  Run "gitline help [command]" for specific usage
  '
fi
}

########################################################################################################################
########################################################################################################################


# Determining Which Method To Call Based On Command Line Arguments
if [ $whichMethod == "addLabel" ]
  then addLabel
elif [ $whichMethod == "removeLabel" ]
  then removeLabel
elif [ $whichMethod == "addAssignee" ]
  then addAssignee
elif [ $whichMethod == "removeAssignee" ]
  then removeAssignee
elif [ $whichMethod == "listAssignees" ]
  then listAssignees
elif [ $whichMethod == "listLabels" ]
  then listLabels
elif [ $whichMethod == "addComment" ]
  then addComment
elif [ $whichMethod == "toQA" ]
  then toQA
elif [ $whichMethod == "toInProgress" ]
  then toInProgress
elif [ $whichMethod == "addArray" ]
  then addArray
elif [ $whichMethod == "removeArray" ]
  then removeArray
elif [ $whichMethod == "status" ]
  then status
elif [ $whichMethod == "st" ]
  then status
elif [ $whichMethod == "clearArray" ]
  then clearArray
elif [ $whichMethod == "loopQA" ]
  then loopQA
elif [ $whichMethod == "ac" ]
  then ac
elif [ $whichMethod == "help" ]
  then
  specificCommand=$2
  help
elif [ $whichMethod == "config" ]
  then
  setToken=$2
  setOwner=$3
  setRepo=$4
  setGH_Username=$5
  setQA_Username=$6
  config
else
  echo '
  ERROR: invalid command
  run "gitline help" for a list of available commands.
  '
fi

