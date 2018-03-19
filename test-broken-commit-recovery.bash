#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./broken-commit.XXXXXX)

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

  git add e/e
  git commit -m "Add e"

  COMMIT=$(git rev-parse HEAD^)
  COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')

  git cat-file -p $COMMIT

  git fsck

  git branch -D branch-b
  git reflog delete HEAD@{5} HEAD@{4} HEAD@{3} HEAD@{2}

  git fsck

  chmod +w $COMMIT_FILE
  echo > $COMMIT_FILE
  chmod -x $COMMIT_FILE

  git log || true
  git fsck || true
)

rmtrash $WORKSPACE
