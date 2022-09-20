#!/bin/bash

# Helper function to gracefully shut down our child processes when we exit.
clean_exit() {
    for PID in "${NGINX_PID}" "${CERTBOT_LOOP_PID}"; do
        if kill -0 "${PID}" 2>/dev/null; then
            kill -SIGTERM "${PID}"
            wait "${PID}"
        fi
    done
}

# Such script is alternatively available compared to official solution: https://aws.amazon.com/premiumsupport/knowledge-center/ecs-iam-task-roles-config-errors/
storeAWSTemporarySecurityCredentials() {

  # Skip AWS credentials processing if env URI is not present
  [ -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ] && return

  # Query the unique security credentials generated for the task.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  USER_AWS_SETTINGS_FOLDER=~/.aws
  [ ! -d "$USER_AWS_SETTINGS_FOLDER" ] && mkdir -p $USER_AWS_SETTINGS_FOLDER

  AWS_CREDENTIALS=$(curl 169.254.170.2${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI})

  AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq '.AccessKeyId' --raw-output)
  AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq '.SecretAccessKey' --raw-output)
  AWS_SESSION_TOKEN=$(echo $AWS_CREDENTIALS | jq '.Token' --raw-output)

  USER_AWS_CREDENTIALS_FILE=${USER_AWS_SETTINGS_FOLDER}/credentials
  touch $USER_AWS_CREDENTIALS_FILE

  # Set the temporary credentials to the default AWS profile.
  # Note the corresponding security token must be included to sign your S3 request with the temporary security credentials.
  # https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html#UsingTemporarySecurityCredentials
  echo '[default]' > $USER_AWS_CREDENTIALS_FILE
  echo "aws_access_key_id=${AWS_ACCESS_KEY_ID}" >> $USER_AWS_CREDENTIALS_FILE
  echo "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" >> $USER_AWS_CREDENTIALS_FILE
  echo "aws_session_token=${AWS_SESSION_TOKEN}" >> $USER_AWS_CREDENTIALS_FILE
}

storeAWSTemporarySecurityCredentials

# run nginx in the background
nginx -g "daemon off;" &
NGINX_PID=$!

# Make bash listen to the SIGTERM, SIGINT and SIGQUIT kill signals, and make
# them trigger a normal "exit" command in this script. Then we tell bash to
# execute the "clean_exit" function, seen above, in the case an "exit" command
# is triggered. This is done to give the child processes a chance to exit
# gracefully.
# trap 'exit' TERM INT QUIT
# trap 'clean_exit' EXIT

# Other function to trigger certbot webroot renewal, TBD
