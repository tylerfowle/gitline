#!/bin/bash
# gitline - github api script
############################################################

progName=Gitline
progVersion=0.2.0
SUBJECT=gitline
USAGE="gitline command issueNumber assignee_or_Label"

#github api
DOMAIN="https://api.github.com"

# holds per user config info
CONFIG_FILE=~/gitline_config.sh
CONFIG_FILE_BAK=~/gitline_config.sh.bak

# holds array
QA_FILE=~/gitline_qas.txt
MILESTONES_FILE=~/gitline_milestones.txt

# variables
whichMethod=$1
issueNumber=$2
assignee_or_label=$3

jq_is_available=false

############################################################

# check to see if config file exists
if [ -f $CONFIG_FILE ]; then
  source $CONFIG_FILE
else
  echo '
  ERROR: missing config file. creating new file.
  run "gitline config :token :github_username"
  '
  # create files
  echo '# gitline config' >> $CONFIG_FILE
  exit
fi

# test if jq is available
if ! [ -x "$(command -v jq)" ]; then
  jq_is_available=false
else
  jq_is_available=true
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



function echoFormattedJSON() {
  if [ "$jq_is_available" = true ]; then
    echo $1 | jq .
  else
    echo $1
  fi
}




# usage
# getCreator
# This call lists all the available assignees to which issues may be assigned. (repo)
function getCreator() {

  if [ "$jq_is_available" = true ]; then

    getCreator=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber} )
    creatorUsername=$(echo "$getCreator" | jq .user.login)
    creatorUsername="${creatorUsername%\"}"
    creatorUsername="${creatorUsername#\"}"
    QAUSER=$creatorUsername
    echo "$QAUSER"

    # set qa github username
    # echo "QAUSER=$creatorUsername" >> $CONFIG_FILE

  else
    echo "jq not installed. some functionality may be limited."
  fi

}


# usage
# listAssignees
# This call lists all the available assignees to which issues may be assigned. (repo)
function listAssignees() {
  listAssignees=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/assignees)
  echoFormattedJSON "$listAssignees"
}
# usage
# listLables [issueNumber]
# List labels on an issue
function listLabels() {
  listLabels=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels)
  echoFormattedJSON "$listLabels"
}
# usage
# listAllLabels
# List labels on an issue
function listAllLabels() {
  listAllLabels=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/labels)
  listAllLabels=$(echo "$listAllLabels" | jq '.[].name' )

  echo ">> All available labels in repo $REPO"
  echoFormattedJSON "$listAllLabels"
}


############################################################

# usage
# addAssignee [issueNumber] [assigneUsername]
# removeAssignee [issueNumber] [assigneUsername]
# add a single assignee to an issue
function addAssignee() {
  addAssignee=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/assignees -X POST -H "Content-Type: application/json" --data '{ "assignees":["'${assignee_or_label}'"]}')
  echoFormattedJSON "$addAssignee"
}
# remove a single assignee to an issue
function removeAssignee() {
  removeAssignee=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/assignees -X DELETE -H "Content-Type: application/json" --data '{ "assignees":["'${assignee_or_label}'"]}')
  echoFormattedJSON "$removeAssignee"
}



# encode a url
function urlencode() {
  local _length="${#1}"
  for (( _offset = 0 ; _offset < _length ; _offset++ )); do
    _print_offset="${1:_offset:1}"
    case "${_print_offset}" in
      [a-zA-Z0-9.~_-]) printf "${_print_offset}" ;;
      ' ') printf + ;;
      *) printf '%%%X' "'${_print_offset}" ;;
    esac
  done
}

# download a specific file from a private github repo
function downloadFile() {
  encodedBranch=$(urlencode $branch)
  FILE="https://api.github.com/repos/$OWNER/$customrepo/contents/$filepath?ref=$encodedBranch"
  curl -u ${TOKEN}:x-oauth-basic\
    --header 'Accept: application/vnd.github.v3.raw' \
    -o $(basename $filepath) \
    --remote-name \
    --location $FILE
}

############################################################

# usage
# addLabel [issueNumber] [labelToApply]
# removeLabel [issueNumber] [labelToApply]
# add a label to an issue
function addLabel() {
  addLabel=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels -X POST -H "Content-Type: application/json" --data '["'${assignee_or_label}'"]')
  echoFormattedJSON "$addLabel"
}
# remove a label from an issue
function removeLabel() {
  removeLabel=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/labels/${assignee_or_label} -X DELETE)
  echoFormattedJSON "$removeLabel"
}

############################################################

# usage
# addComment [issueNumber] [commentContent]
# add a comment to an issue
function addComment() {
  addComment=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber}/comments -X POST -H "Content-Type: application/json" --data '{ "body":"'"$assignee_or_label"'"}')
  echoFormattedJSON "$addComment"
}

############################################################

# usage
# addMilestone [issueNumber] [milestone id]
# add specific issue to a milestone
function addMilestone() {
  addMilestone=$(curl --silent -u ${TOKEN}:x-oauth-basic ${DOMAIN}/repos/${OWNER}/${REPO}/issues/${issueNumber} -X PATCH -H "Content-Type: application/json" --data '{ "milestone":'${assignee_or_label}'}')
  echoFormattedJSON "$addMilestone"
}

############################################################

# send issue to QA
# usage
# sendQA [issueNumber]
function sendQA() {
  assignee_or_label="InReview"
  addLabel
  assignee_or_label="InProgress"
  removeLabel

  assignee_or_label=${GHUSER}
  removeAssignee
  getCreator
  assignee_or_label=${QAUSER}
  addAssignee
}

# add label InProgress to issue
# usage
# sendProgress [issueNumber]
function sendProgress() {
  assignee_or_label="InReview"
  removeLabel
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
  selectedFile=$QA_FILE
  sendProgress
  arrayAdd
}

############################################################

# add issue number to an array
function arrayAdd() {
  userSelectFile
  if [ -f $selectedFile ]; then
    echo ''
  else
    echo '' >> $selectedFile
  fi
  echo "${issueNumber}" >> $selectedFile
}
# remove issue number from temp file
function arrayRemove() {
  userSelectFile
  sed -i '' 's/'${issueNumber}'//g' $selectedFile
  status
}
# clear that array
function arrayClear() {
  userSelectFile
  > $selectedFile
  cat $selectedFile
}

# echo issue numbers in temp file
function status() {
  userSelectFile
  echo '>> Issues currently stored'
  cat $selectedFile;
  echo '>> ##########'
}

# loop through each issue number in the array and send it [sendQA]
# no args
# usage:
# gitline loop
function loop() {
  userSelectFile
  while read p; do
    echo $p
    issueNumber=$p
    if [[ $selectedFile == $QA_FILE ]]; then
      sendQA
    elif [[ $selectedFile == $MILESTONES_FILE ]]; then
      addMilestone
    fi
  done <$selectedFile
  arrayClear
}
############################################################


function userSelectFile() {
  selectedFile=$QA_FILE
}



########################################################################################################################
########################################################################################################################
# help | documention
############################################################

function helpCommand() {
  specificCommand=$1;
  case $1 in
    ###########################################################
    getCreator )
    echo '
    Description:
    -get the creator of an issue

    Usage:
    gitline getCreator [Issue Number]
    '
    ;;
    ###########################################################
    addLabel )
    echo '
    Description:
    -add a single label to a specific issue number

    Usage:
    gitline addLabel [Issue Number] [Label to add]
    '
    ;;
    ############################################################
    removeLabel )
    echo '
    Description:
    -remove a single label from a specific issue number

    Usage:
    gitline removeLabel [Issue Number] [Label to remove]
    '
    ;;
    ############################################################
    addAssignee )
    echo '
    Description:
    -add an assignee to a specific issue number

    Usage:
    gitline addAssignee [Issue Number] [Assignee to add]
    '
    ;;
    ############################################################
    removeAssignee )
    echo '
    Description:
    -remove an assignee from a specific issue number

    Usage:
    gitline removeAssignee [Issue Number] [Assignee to remove]
    '
    ;;
    ############################################################
    listAssignees )
    echo '
    Description:
    -list all assignees availble to assigne in this repo

    Usage:
    gitline listAssignees
    '
    ;;
    ############################################################
    listLabels )
    echo '
    Description:
    -list all labels currently applied to a specific issue number

    Usage:
    gitline listLabels [Issue Number]
    '
    ;;
    ############################################################
    listAllLabels )
    echo '
    Description:
    -list all labels currently available in repo

    Usage:
    gitline listAllLabels
    '
    ;;
    ############################################################
    addComment )
    echo '
    Description:
    -add a comment to a specific issue number

    Usage:
    gitline addComment [Issue Number] ["Comment in quotes"]
    '
    ;;
    ############################################################
    addMilestone )
    echo '
    Description:
    -add a milestone to a specific issue number

    Usage:
    gitline addComment [Issue Number] [Milestone ID]
    '
    ;;
    ############################################################
    sendQA )
    echo '
    Description:
    -send a specific issue number to QA. this includes:
    removing "InProgress" label
    adding "InReview" label
    removing self as assignee
    adding qa user as assignee

    Usage:
    gitline sendQA [Issue Number]
    '
    ;;
    ############################################################
    sendProgress )
    echo '
    Description:
    -add "InProgress" label to a specific issue number

    Usage:
    gitline sendProgress [Issue Number]
    '
    ;;
    ############################################################
    arrayAdd )
    echo '
    Description:
    -add issue number to array for using later in loop

    Usage:
    gitline arrayAdd [Issue Number]
    '
    ;;
    ############################################################
    arrayRemove )
    echo '
    Description:
    -remove issue number from array for using later in loop

    Usage:
    gitline arrayRemove [Issue Number]
    '
    ;;
    ############################################################
    status )
    echo '
    Description:
    -print all issue numbers currently in array

    Usage:
    gitline status
    '
    ;;
    ############################################################
    arrayClear )
    echo '
    Description:
    -remove all issues from array

    Usage:
    gitline arrayClear
    '
    ;;
    ############################################################
    loop )
    echo '
    Description:
    -loop through issue number array and do either: sendQA or addMilestone
    run "gitline help sendQA" for more information
    run "gitline help addMilestone" for more information

    Usage:
    gitline loop
    '
    ;;
    ############################################################
    ac )
    echo '
    Description:
    -add and commit a message to git appended with an issue number.
    -add "InProgress" label to issue
    -add issue number to array for use later in loop.
    run "gitline help sendProgress" for more information

    Usage:
    gitline ac [Issue Number] ["Comment to commit on github in quotes"]
    '
    ;;
    ############################################################
    help )
    echo '
    Description:
    -learn more about gitline, optional: add a [specific command]

    Usage:
    gitline -h
    gitline -h [specificCommand]
    gitline help
    gitline help [specific command]
    '
    ;;
    ############################################################
    config )
    echo '
    Description:
    -add config settings to config file

    There are two methods for setting config options.
    --------------------------------------------------------------------------------------------------
    Basic - this requires parameters to be in the specific order. to add a new [repo] you
    would have to also specify all previous parameters in the correct order.
    Usage:
    gitline config [token] [owner] [repo] [github username] [qa username]
    --------------------------------------------------------------------------------------------------
    Advanced - this method can take any number of parameters in an order.
    Usage:
    gitline --token=[token] --owner=[owner] --repo=[repo] --username=[your username] --qausername[qa username]
    --------------------------------------------------------------------------------------------------
    '
    ;;
    ############################################################


    ############################################################
    * )
    echo '
    Commands:
    help
    config
    getCreator
    addLabel
    removeLabel
    addAssignee
    removeAssignee
    listAssignees
    listLabels
    listAllLabels
    addComment
    addMilestone
    sendQA
    sendProgress
    arrayAdd
    arrayRemove
    status
    arrayClear
    loop
    ac

    Run "gitline help [command]" for specific usage
    '
    ;;
esac
}

########################################################################################################################
########################################################################################################################


# Determining Which Method To Call Based On Command Line Arguments
case $whichMethod in
  getCreator     ) getCreator ;;
  addLabel       ) addLabel ;;
  addAssignee    ) addAssignee ;;
  addComment     ) addComment ;;
  addMilestone   ) addMilestone ;;
  removeLabel    ) removeLabel ;;
  removeAssignee ) removeAssignee ;;
  sendQA         ) sendQA ;;
  sendProgress   ) sendProgress ;;
  listAssignees  ) listAssignees ;;
  listLabels     ) listLabels ;;
  listAllLabels  ) listAllLabels ;;
  arrayAdd       ) arrayAdd ;;
  arrayRemove    ) arrayRemove ;;
  arrayClear     ) arrayClear ;;
  status         ) status ;;
  st             ) status ;;
  loop           ) assignee_or_label=$2; loop ;;
  ac             ) ac ;;
  download       ) customrepo=$2; branch=$3; filepath=$4; downloadFile ;;
  help           )
    helpCommand $2;
    ;;
  -*             ) ;;
  config         )
    setToken=$2
    setOwner=$3
    setRepo=$4
    setGH_Username=$5
    setQA_Username=$6;
    config
    ;;
  * )
    echo ""
    echo "$progName $progVersion"
    echo '
    ERROR: invalid command
    run "gitline help" for a list of available commands.
    '
    echo ""
    ;;
esac




########################################################################################################################
# fancy config with -short --long options
########################################################################################################################
while getopts :-: arg; do
  case $arg in
    # c )  ARG_C=$OPTARG; echo '-c was selected' $OPTARG ;;
    - ) LONG_OPTARG="${OPTARG#*=}"
      case $OPTARG in
        username=?* )
          echo 'GHUSER='${LONG_OPTARG} >> $CONFIG_FILE;
          echo 'added github [your username] to config';
          ;;
        token=?* )
          echo 'TOKEN='${LONG_OPTARG} >> $CONFIG_FILE;
          echo 'added [token] to config';
          ;;
        owner=?* )
          echo 'OWNER='${LONG_OPTARG} >> $CONFIG_FILE;
          echo 'added github [organization or owner] to config';
          ;;
        repo=?* )
          echo 'REPO='${LONG_OPTARG} >> $CONFIG_FILE;
          echo 'added github [repo] to config';
          ;;
        qausername=?* )
          echo 'QAUSER='${LONG_OPTARG} >> $CONFIG_FILE;
          echo 'added github [qa person username] to config';
          ;;

        username*   ) echo "No arg allowed for --OPTARG options"; exit 2;;
        token*      ) echo "No arg allowed for --OPTARG options"; exit 2;;
        owner*      ) echo "No arg allowed for --OPTARG options"; exit 2;;
        repo*       ) echo "No arg allowed for --OPTARG options"; exit 2;;
        qausername* ) echo "No arg allowed for --OPTARG options"; exit 2;;

        # bravo=?* )  ARG_B="$LONG_OPTARG"; echo '--bravo was selected' ;;
        # bravo*   )  echo "No arg for --$OPTARG option" exit 2 ;;
        # charlie  )  ARG_C=true; echo '--charlie was selected' ;;
        # alpha* | charlie* )
          #             echo "No arg allowed for --$OPTARG option"; exit 2 ;;
        '' )        break ;; # "--" terminates argument processing
        * )         echo "Illegal option --$OPTARG"; exit 2 ;;
      esac ;;
    \? ) exit 2 ;;  # getopts already reported the illegal option
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list
########################################################################################################################
