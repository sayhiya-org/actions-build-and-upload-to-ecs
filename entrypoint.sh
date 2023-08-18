#!/bin/sh
set -e

function main() {
  sanitize "${INPUT_ACCESS_KEY_ID}" "access_key_id"
  sanitize "${INPUT_SECRET_ACCESS_KEY}" "secret_access_key"
  sanitize "${INPUT_REGION}" "region"
  sanitize "${INPUT_ACCOUNT_ID}" "account_id"

  ACCOUNT_URL="$INPUT_ACCOUNT_ID.dkr.ecr.$INPUT_REGION.amazonaws.com"

  aws_configure
  login
  docker_build $INPUT_TAGS $ACCOUNT_URL
  create_ecr_repo $INPUT_CREATE_REPO
  docker_push_to_ecr $INPUT_TAGS $ACCOUNT_URL
}

function sanitize() {
  if [ -z "${1}" ]; then
    >&2 echo "Unable to find the ${2}. Did you set with.${2}?"
    exit 1
  fi
}

function aws_configure() {
  export AWS_ACCESS_KEY_ID=$INPUT_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$INPUT_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$INPUT_REGION
}

function login() {
  echo "Attempting to log into AWS"
  LOGIN_PASSWORD=$(aws ecr get-login-password --region $AWS_DEFAULT_REGION)
  echo "$LOGIN_PASSWORD" | docker login --username AWS --password-stdin $ACCOUNT_URL
  echo "Login Successful!"
}

function docker_build() {
  echo "Attempting to build docker image"
  docker build . --build-arg $INPUT_EXTRA_BUILD_ARGS -f $INPUT_DOCKERFILE
  echo "Build Successful!"
}

function docker_push_to_ecr() {
  echo "Attempting to push docker image"
  local TAG=$1
  local DOCKER_TAGS=$(echo "$TAG" | tr "," "\n")
  for tag in $DOCKER_TAGS; do
    docker push $2/$INPUT_REPO:$tag
  done
  echo "== FINISHED PUSH TO ECR"
}

main
