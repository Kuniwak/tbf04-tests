#!/bin/bash -eux
set -o pipefail

workspace=$(mktemp -d ./clean-after-stash-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
  echo c > c
  echo c > .gitignore
  git add a .gitignore
  git commit -m "Add a"

  git clean -ndx
  git stash --all
  git clean -fdx

  git stash pop
  ls
)

rmtrash $workspace
