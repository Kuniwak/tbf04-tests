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

  TREE=$(git cat-file -p HEAD | head -1 | sed -e 's/^tree //')
  TREE_FILE=$(echo $TREE | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')

  git cat-file -p $TREE

  chmod +w $TREE_FILE
  echo > $TREE_FILE
  chmod -x $TREE_FILE

  git log || true
  git diff HEAD || true
  git fsck || true
)

rmtrash $WORKSPACE
