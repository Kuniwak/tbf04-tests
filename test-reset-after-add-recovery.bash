#!/bin/bash -eux
set -o pipefail

workspace=$(mktemp -d ./reset-after-add-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
  git add a
  git commit -m "Add a"

  git add b
  git reset --hard HEAD

  git fsck
  dangling_blob=$(git fsck | grep 'dangling blob' | sed -e 's/^dangling blob \([0-9a-f]*\)/\1/')

  git show $dangling_blob
)

rm -rf $workspace
