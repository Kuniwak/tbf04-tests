#!/bin/bash -eux
set -o pipefail


workspace=$(mktemp -d ./commit-amend-identiry.XXXXXX)

(cd $workspace
  git init
	git commit --allow-empty -m "Initial commit"

  echo a > a
  git add a
  git commit -m "Add a"
  git rev-parse HEAD

  export GIT_AUTHOR_DATE=$(git log -1 --format=%aD)
  export GIT_COMMITTER_DATE=$(git log -1 --format=%cD)

  git commit --amend --no-edit
  git rev-parse HEAD
)

rm -rf $workspace
