#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./reset-after-reflog-recovery.XXXXXX)

(cd $WORKSPACE
  git init

  for i in {1..5}; do
    echo $i > hoge
    git add hoge
    git commit -m "Increment hoge to $i"
  done

  git reset --hard HEAD^

  git checkout -b work-1

  for i in {6..10}; do
    echo $i > hoge
    git add hoge
    git commit -m "Increment hoge to $i"
  done

  git checkout master
  git merge work-1

  git reflog master
)

rmtrash $WORKSPACE
