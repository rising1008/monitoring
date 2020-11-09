#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname $0)" || exit; pwd)
eval "$(cat ${SCRIPT_DIR}/.env <(echo) <(declare -x))"

: ==================================================
:  Constants
: ==================================================
SYSTEM_ID=${SYSTEM_ID:-Dummy}
COMPONENT_ID=${COMPONENT_ID:-Dummy}
S3_BUCKET_NAME=${S3_BUCKET_NAME:-$$-cfn-templates-store}
S3_PATH="s3://${S3_BUCKET_NAME}/${SYSTEM_ID}/${COMPONENT_ID}"
EXPIRE_DURATION=300
PIPELINE_TMPL_LIST="
dashboard-definition.yml
dashboard-resources/dashboard.yml
dashboard-resources/cloudtrail.yml
dashboard-resources/synthetics.yml
"
LAMBDA_ZIP_NAME=$$-lambda.zip
[ -n "${AWS_PROFILE}" ] && AWS_CLI_OPTION="--profile ${AWS_PROFILE}"

: ==================================================
:  Functions
: ==================================================
function validate() {
  error_flag=false

  for template in $(cat)
  do
    error=$(aws ${AWS_CLI_OPTION} cloudformation validate-template --template-body file://./src/cfn/${template} 2>&1 > /dev/null)
    if [ $? -eq 0 ]
    then
      echo -e "      ${template} ----- \u001b[32m✔︎\u001b[0m"
    else
      error_flag=true
      echo -e "      ${template} ----- \u001b[31m✖︎\u001b[0m"
      echo -e "\u001b[31m${error}\u001b[0m\n"
    fi
  done

  if ${error_flag}
  then
    exit 1
  fi
}

function lambdaCodeUpload() {
  cd ./src/lambda
  zip -r "../../${LAMBDA_ZIP_NAME}" ./ 2>&1 > /dev/null
  cd ../..
  error=$(aws ${AWS_CLI_OPTION} s3 cp ./${LAMBDA_ZIP_NAME} ${S3_PATH}/lambda/${LAMBDA_ZIP_NAME} 2>&1 > /dev/null)
  if [ $? -eq 0 ]
  then
    echo -e "      lambdaUpload success"
    rm ./${LAMBDA_ZIP_NAME}
  else
    echo -e "      \u001b[31m${error}\u001b[0m\n"
    rm ./${LAMBDA_ZIP_NAME}
    exit 1
  fi
}

function generateSignedUrl() {
  for TMPL in $(cat)
  do
    echo $(aws ${AWS_CLI_OPTION} s3 presign ${S3_PATH}/cfn/${TMPL} --expires-in $EXPIRE_DURATION)
  done
}

function createStack() {
  local readonly STACK_NAME=$1
  local readonly TEMPLATE=$2
  local readonly PARAMETERS=$3
  local readonly TAGS=$4

  aws ${AWS_CLI_OPTION} \
    cloudformation create-stack \
    --stack-name ${STACK_NAME} \
    --template-url ${TEMPLATE} \
    --parameters ${PARAMETERS} \
    --capabilities CAPABILITY_NAMED_IAM \
    --on-failure DELETE \
    --tags ${TAGS}
  aws ${AWS_CLI_OPTION} cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
}

function updateStack() {
  local readonly STACK_NAME=$1
  local readonly TEMPLATE=$2
  local readonly PARAMETERS=$3
  local readonly TAGS=$4

  aws ${AWS_CLI_OPTION} \
    cloudformation update-stack \
    --stack-name ${STACK_NAME} \
    --template-url ${TEMPLATE} \
    --parameters ${PARAMETERS} \
    --capabilities CAPABILITY_NAMED_IAM \
    --tags ${TAGS}
  aws ${AWS_CLI_OPTION} cloudformation wait stack-update-complete --stack-name ${STACK_NAME}
}

: ==================================================
:  Sanity check
: ==================================================
if !(command -v aws > /dev/null 2>&1)
then
  printf -- "[Error]: You don\'t seem to have AWS CLI installed.\n"
  printf -- "         Get it: https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-install.html\n"
  exit 127
fi

: ==================================================
:  Main
: ==================================================
echo -e "\n  deploy dashboard... \n"

echo -e "    [1] validate CFn templates \n"
echo ${PIPELINE_TMPL_LIST} | validate
[ $? -ne 0 ] && exit 1
echo -e "      \u001b[32mdone\u001b[0m \n"

echo -e "    [2] upload lambda code to S3 bucket \n"
lambdaCodeUpload
echo -e "      \u001b[32mdone\u001b[0m \n"

echo -e "    [3] upload to S3 bucket \n"
aws ${AWS_CLI_OPTION} s3 sync ./src ${S3_PATH} --exclude ".git/*" --exclude "*/node_modules/*" --exclude "*/artifacts/*" --exclude "*/build/*" --exclude "*/coverage/*"
echo -e "      \u001b[32mdone\u001b[0m \n"

echo -e "    [4] generate signed urls \n"
PIPELINE_URLS=($(echo ${PIPELINE_TMPL_LIST} | generateSignedUrl))
echo -e "      \u001b[32mdone\u001b[0m \n"

PIPELINE_STACK_NAME="${SYSTEM_ID}-${COMPONENT_ID}-dashboard"
PIPELINE_PARAMETERS="
ParameterKey=SystemID,ParameterValue=${SYSTEM_ID}
ParameterKey=ComponentID,ParameterValue=${COMPONENT_ID}
ParameterKey=DashboardTmplPath,ParameterValue=${PIPELINE_URLS[1]}
ParameterKey=CloudTrailTmplPath,ParameterValue=${PIPELINE_URLS[2]}
ParameterKey=SyntheticsTmplPath,ParameterValue=${PIPELINE_URLS[3]}
ParameterKey=TableName,ParameterValue=${TABLE_NAME}
ParameterKey=ApiName,ParameterValue=${API_NAME}
ParameterKey=ImporterPipelineName,ParameterValue=${IMPORTER_PIPELINE_NAME}
ParameterKey=3dModelImporterRepositoryArn,ParameterValue=${IMPORTER_REPOSITORY_ARN}
ParameterKey=LambdaCodeBucket,ParameterValue=${S3_BUCKET_NAME}
ParameterKey=LambdaCodeKey,ParameterValue=${SYSTEM_ID}/${COMPONENT_ID}/lambda/${LAMBDA_ZIP_NAME}
ParameterKey=FrontendUrl,ParameterValue=${FRONTEND_URL}
ParameterKey=BackendUrl,ParameterValue=${BACKEND_URL}
ParameterKey=UserPoolId,ParameterValue=${USER_POOL_ID}
ParameterKey=ClientId,ParameterValue=${CLIENT_ID}
ParameterKey=CognitoUsername,ParameterValue=${COGNITO_USERNAME}
ParameterKey=CognitoPassword,ParameterValue=${COGNITO_PASSWORD}
"

TAGS="
Key="SystemID",Value="${SYSTEM_ID}"
Key="ComponentID",Value="${COMPONENT_ID}"
"

echo -e "    [5] deploy stack of dashboard\n"
error=$(aws ${AWS_CLI_OPTION} cloudformation describe-stacks --stack-name "${PIPELINE_STACK_NAME}" 2>&1 > /dev/null)
if [ $? -ne 0 ]; then
  createStack ${PIPELINE_STACK_NAME} ${PIPELINE_URLS[0]} "${PIPELINE_PARAMETERS}" "${TAGS}"
else
  updateStack ${PIPELINE_STACK_NAME} ${PIPELINE_URLS[0]} "${PIPELINE_PARAMETERS}" "${TAGS}"
fi
echo -e "      \u001b[32mdone\u001b[0m \n"
