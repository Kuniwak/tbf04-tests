#!/bin/sh -eux
set -o pipefail

workspace=$(mktemp -d ./reset-after-stash-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
  echo c > c
  git add a
  git commit -m "Add a"
  echo aa > a

  git stash -u
  git stash clear

  git reset --hard HEAD

  git fsck
  dangling_commit=$(git fsck | grep 'dangling commit' | sed -e 's/^dangling commit \([0-9a-f]*\)/\1/')
  git log --graph --oneline $dangling_commit
)

rm -rf $workspace
