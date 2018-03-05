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

  git fsck
  DANGLING_BLOB=$(git fsck | grep 'dangling blob' | sed -e 's/^dangling blob \([0-9a-f]*\)/\1/')

  git show $DANGLING_BLOB
)

rmtrash $WORKSPACE
