#!/bin/bash

source ./ci/functions.sh

CAS_VERSION=${1:-$DEFAULT_CAS_VERSION}
BOOT_VERSION=${2:-$DEFAULT_BOOT_VERSION}
BRANCH=${3:-master}

java -jar app/build/libs/app.jar &
pid=$!
sleep 15
mkdir tmp
cd tmp

echo "Building Overlay ${CAS_VERSION} with Spring Boot ${BOOT_VERSION} for branch ${BRANCH}"
curl http://localhost:8080/starter.tgz \
  -d baseDir=initializr \
  -d "casVersion=${CAS_VERSION}&bootVersion=${BOOT_VERSION}" | tar -xzvf -
kill -9 $pid

echo "Cloning CAS overlay repository branch ${BRANCH}..."

if [ -z "$GH_TOKEN" ] ; then
  echo -e "\nNo GitHub token is defined."
  exit 1
fi

git clone --single-branch --branch ${BRANCH} \
  https://${GH_TOKEN}@github.com/apereo/cas-overlay-template /tmp/overlay-repo
if [ $? -ne 0 ] ; then
  echo "Could not successfully clone the repository branch"
  exit 1
fi

echo "Moving .git directory into generated overlay"
mv /tmp/overlay-repo/.git ./initializr
rm -Rf /tmp/overlay-repo

echo "Configuring git..."
cd ./initializr && pwd
git config user.email "cas@apereo.org"
git config user.name "CAS"

echo "Checking repository status..."
git status

echo "Updating project README"
warning="# WARNING \n"
warning="******************************************************\n"
warning="${warning}This repository is always automatically generated from the CAS Initializr.\n"
warning="${warning}To learn more, please visit the [CAS documentation](https://apereo.github.io/cas).\n\n"
warning="******************************************************\n"
text=$(echo "${warning}"; cat README.md)
echo "${text}" > README.md

echo "Committing changes..."
git add --all
git commit -am "Synced repository from CAS Initializr"
git status

echo "Pushing changes to branch ${BRANCH}"
git push --set-upstream origin ${BRANCH} --force
if [ $? -ne 0 ] ; then
  echo "Could not successfully push changes to the repository branch"
  exit 1
fi
echo "Done"
exit 0
