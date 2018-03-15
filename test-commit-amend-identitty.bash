#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./commit-amend-identiry.XXXXXX)

(cd $WORKSPACE
  git init
	git commit --allow-empty -m "Initial commit"

  echo a > a
  git add a
  git commit -m "Add a"
  git rev-parse HEAD

  GIT_AUTHOR_DATE=$(git log -1 --format=%aD)
  GIT_COMMITTER_DATE=$(git log -1 --format=%cD)

  git commit --amend --no-edit
  git rev-parse HEAD
)

rmtrash $WORKSPACE
