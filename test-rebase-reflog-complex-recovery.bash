#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./rebase-reflog-complex-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
	echo c > c
	echo d > d
	echo e > e
  git add a
  git commit -m "Add a"

  git add b
  git commit -m "Add b"

  git checkout -b branch-c HEAD@{1}

  git add c
  git commit -m "Add c"

  git add d
  git commit -m "Add d"

  git checkout -b branch-e

  git add e
  git commit -m "Add e"

  git checkout branch-c

  git rebase master
  git log --oneline
  git reflog

  git show HEAD@{4}
)

rmtrash $WORKSPACE