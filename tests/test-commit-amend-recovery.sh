#!/bin/sh -eux
set -o pipefail

workspace=$(mktemp -d ./reset-commit-amend-recovery.XXXXXX)

(cd $workspace
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

rm -rf $workspace
