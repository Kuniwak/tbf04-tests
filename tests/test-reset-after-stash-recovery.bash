#!/bin/bash -eux
set -o pipefail

workspace=$(mktemp -d ./reset-after-stash-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
  git add a
  git commit -m "Add a"

  git add b
  git stash
  git stash clear

  git reset --hard HEAD

  git fsck
)

rm -rf $workspace
