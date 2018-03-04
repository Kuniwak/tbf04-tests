#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-after-add-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
  git add a
  git commit -m "Add a"

  git add b
  git reset --hard HEAD

  git fsck --dangling
)

rmtrash $WORKSPACE
