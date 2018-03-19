#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-commit-amend-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
  echo c > c
  git add a
  git commit -m "Add a"

  git add b
  git commit -m "Add b"

  git add c
  git commit --amend -m "Add b and c"

  git reflog
  git show HEAD@{1}
)

rmtrash $WORKSPACE
