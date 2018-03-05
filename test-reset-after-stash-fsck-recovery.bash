#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-after-stash-fsck-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
	echo c > c
  git add a
  git commit -m "Add a"

  git add b
  git stash -u
  git stash clear

  git fsck
  DANGLING_COMMIT=$(git fsck | grep 'dangling commit' | sed -e 's/^dangling commit \([0-9a-f]*\)/\1/')

  git log $DANGLING_COMMIT --graph --oneline
  git show $DANGLING_COMMIT^@
  git cherry-pick $DANGLING_COMMIT --mainline 1 --no-commit
)

rmtrash $WORKSPACE
