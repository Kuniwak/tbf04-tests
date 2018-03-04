#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-after-stash-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
  git add a
  git commit -m "Add a"

  git add b
  git stash
  git stash pop
  rm b

  git reset --hard HEAD

  git fsck --dangling
)

rmtrash $WORKSPACE
