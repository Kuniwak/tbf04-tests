#!/bin/bash -eu
set -o pipefail

WORKSPACE=$(mktemp -d ./reset-branch-d-recovery.XXXXXX)

(cd $WORKSPACE
  mkdir origin
  pushd origin
  git init

  echo a > a
  echo b > b
  echo c > c
  echo c > .gitignore

  git add a .gitignore
  git commit -m "Add a"

  git status
  popd

  git clone ./origin clone
  pushd clone

  ls
  git ls-files
)

rmtrash $WORKSPACE
