#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./object-storage.XXXXXX)

(cd $WORKSPACE
  git init

  echo a > a
  echo b > b
  echo c > c
  echo d > d
  mkdir e
  echo e > e/e

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

  git checkout master

  git add e/e
  git commit -m "Add e"

  COMMIT=$(git rev-parse HEAD)
  TREE=$(git cat-file -p HEAD | head -1 | sed -e 's/^tree //')
  BLOB=$(git cat-file -p $TREE | head -1 | sed -e 's/^[0-9]* [a-z]* \([0-9a-f]*\).*/\1/')
  BLOB_FILE=$(echo $BLOB | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')

  git cat-file -p $BLOB

  chmod +w $BLOB_FILE
  echo > $BLOB_FILE
  chmod -x $BLOB_FILE

  git log || true
  git diff HEAD || true
  git fsck || true
)

rmtrash $WORKSPACE
