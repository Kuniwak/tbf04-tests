#!/bin/bash -eux
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-after-stash-recovery.XXXXXX)

(cd $WORKSPACE
  git init
  echo a > a
  echo b > b
  echo c > c
  git add a
  git commit -m "Add a"
  echo aa > a

  git stash -u
  git stash pop
  rm b
  rm c

  git reset --hard HEAD

  git fsck --dangling
  DANGLING_COMMIT=$(git fsck --dangling | grep 'dangling commit' | sed -e 's/^dangling commit \([0-9a-f]*\)/\1/')
  git log --graph --oneline $DANGLING_COMMIT
)

rmtrash $WORKSPACE
