# Such script is alternatively available compared to official solution: https://aws.amazon.com/premiumsupport/knowledge-center/ecs-iam-task-roles-config-errors/
storeAWSTemporarySecurityCredentials() {

  # Skip AWS credentials processing if env URI is not present
  [ -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ] && return

  # Query the unique security credentials generated for the task.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  USER_AWS_SETTINGS_FOLDER=~/.aws

  # Initialize the folder anyway
  rm -rf $USER_AWS_SETTINGS_FOLDER && mkdir -p $USER_AWS_SETTINGS_FOLDER

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

# Helper function to output debug messages to STDOUT if the `DEBUG` environment
# variable is set to 1.
#
# $1: String to be printed.
debug() {
    if [ 1 = "${DEBUG}" ]; then
        echo "${1}"
    fi
}

# Helper function to output informational messages to STDOUT.
#
# $1: String to be printed.
info() {
    echo "${1}"
}

# Helper function to output warning messages to STDOUT, with bold yellow text.
#
# $1: String to be printed.
warning() {
    (set +x; tput -Tscreen bold
    tput -Tscreen setaf 3
    echo "${1}"
    tput -Tscreen sgr0)
}

# Helper function to output error messages to STDERR, with bold red text.
#
# $1: String to be printed.
error() {
    (set +x; tput -Tscreen bold
    tput -Tscreen setaf 1
    echo "${1}"
    tput -Tscreen sgr0) >&2
}