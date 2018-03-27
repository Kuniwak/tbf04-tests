#!/bin/bash -eux
set -o pipefail

workspace=$(mktemp -d ./reset-after-stash-fsck-recovery.XXXXXX)

(cd $workspace
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
  dangling_commit=$(git fsck | grep 'dangling commit' | sed -e 's/^dangling commit \([0-9a-f]*\)/\1/')

  git log $dangling_commit --graph --oneline
  git show $dangling_commit^@
  git cherry-pick $dangling_commit --mainline 1 --no-commit
)

rmtrash $workspace
