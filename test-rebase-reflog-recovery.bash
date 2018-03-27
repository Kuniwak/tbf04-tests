#!/bin/bash -eux
set -o pipefail

workspace=$(mktemp -d ./rebase-orig-head-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
	echo c > c
	echo d > d
  git add a
  git commit -m "Add a"

  git add b
  git commit -m "Add b"

  git checkout -b branch-c HEAD@{1}

  git add c
  git commit -m "Add c"

  git add d
  git commit -m "Add d"

  git rebase master
  git log --oneline
  git reflog branch-c

  git show branch-c@{1}
)

rmtrash $workspace
