#!/usr/bin/env bash

ENVIRONEMNT=$1

if [ $# = 0 ]; then
  echo -e "[Error] Environment not found. Please set command line variable Demo/Test/Dev ."
  exit 1;
fi

: ==================================================
:  Constants
: ==================================================
INPUT_FILE="users-${ENVIRONEMNT}.csv"
USER_POOL_ID_PARAMETER_STORE_NAME="/skywalker/3d-model-viewer/${ENVIRONEMNT}/UserPoolId"
USER_POOL_ID=$(aws ssm get-parameter --name ${USER_POOL_ID_PARAMETER_STORE_NAME} | jq -r .Parameter.Value)

: ==================================================
:  Functions
: ==================================================
function checkParameters() {
  echo -e "  Check parameters start.\n"
  echo -e "    Target Environment: $ENVIRONEMNT"

  if [ "x$USER_POOL_ID" = "x" ]; then
    echo -e "\n    [Error] USER_POOL_ID not found. Please check AWS ParameterStore: $USER_POOL_ID_PARAMETER_STORE_NAME"
    exit 1;
  fi
  echo -e "    Target User Pool Id: $USER_POOL_ID"

  if [ ! -e $INPUT_FILE ]; then
    echo -e "\n    [Error] '$INPUT_FILE' not not exist. Please upload file to 'cloud9/scripts/' directory."
    exit 1;
  fi
  echo -e "    Users source file: $INPUT_FILE"

  while ISF= read -r row || [[ -n "${row}" ]]; do
    EMAIL=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $1}'`
    PW=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $2}' | sed -e 's/^"\(.*\)".*$/\1/' | sed -e 's/""/"/'`
    LANG=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $3}'`

    if [ "x$EMAIL" = "x" -o "x$PW" = "x" -o "x$LANG" = "x" ]; then
      echo "\n    [Error] Invalid row found on $INPUT_FILE. Please check input CSV."
      exit 1
    fi
  done < $INPUT_FILE
  echo -e "\n  Check parameters complete.\n"
}

function deleteCurrentUsers() {
  echo -e "  Delete current users start.\n"
  CURRENT_USERS=$(aws cognito-idp list-users --user-pool-id ${USER_POOL_ID} | jq -r .Users)

  for username in $(jq -r '.[].Username' <<< $CURRENT_USERS); do
    aws cognito-idp admin-delete-user --user-pool-id ${USER_POOL_ID} --username ${username}
    echo -e "    Deleted username: $username"
  done

  echo -e "\n  Delete current users complete.\n"
}

function createUsers() {
  local firstRowSkipped=false
  local userCount=0

  echo -e "  Create users start.\n"
  while ISF= read -r row || [[ -n "${row}" ]]; do
    if [ $firstRowSkipped = false ]; then
      firstRowSkipped=true
      continue
    fi
    userCount=$((++userCount))

    EMAIL=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $1}'`
    PW=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $2}' | sed -e 's/^"\(.*\)".*$/\1/' | sed -e 's/""/"/'`
    LANG=`echo ${row} | gawk -v FPAT='([^,]+)|(\".+\")' '{print $3}'`

    echo -e "    <$userCount> Loaded data (email/pw/lang): $EMAIL / $PW / $LANG"

    CREATED_USERNAME=$(aws cognito-idp admin-create-user \
      --user-pool-id ${USER_POOL_ID} \
      --username ${EMAIL} \
      --message-action SUPPRESS \
      --user-attributes Name=email,Value=${EMAIL} Name=email_verified,Value=True Name=custom:language,Value=${LANG} \
      | jq -r .User.Username)

    echo -e "        Created Username: $CREATED_USERNAME"

    aws cognito-idp admin-set-user-password \
        --user-pool-id ${USER_POOL_ID} \
        --username ${CREATED_USERNAME} \
        --password ${PW} \
        --permanent

    echo -e "        '${EMAIL}' user's password updated.\n"
  done < $INPUT_FILE
  echo -e "  Create users complete.\n"
}

: ==================================================
:  Main
: ==================================================
echo -e "\nRegister users start.\n"

echo -e "[1] Check parameters\n"
checkParameters
[ $? -ne 0 ] && exit 1

echo -e "[2] Delete current users\n"
deleteCurrentUsers
[ $? -ne 0 ] && exit 1

echo -e "[3] Create users\n"
createUsers
[ $? -ne 0 ] && exit 1

echo -e "\nRegister users complete.\n"
