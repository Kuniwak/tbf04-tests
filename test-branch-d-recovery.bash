#!/bin/bash -eux
set -o pipefail


workspace=$(mktemp -d ./reset-branch-d-recovery.XXXXXX)

(cd $workspace
  git init

  echo a > a
  echo b > b
  echo c > c
  echo d > d

  git add a
  git commit -m "Add a"

  git checkout -b branch-b

  git add c
  git commit -m "Add c"

  git add d
  git commit -m "Add d"

  git checkout master

  git add b
  git commit -m "Add b"

  git branch -D branch-b

  git reflog
)

rmtrash $workspace
