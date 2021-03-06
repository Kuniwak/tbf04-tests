#!/bin/sh -eux
set -o pipefail


workspace=$(mktemp -d ./reset-after-reflog-recovery.XXXXXX)

(cd $workspace
  git init

  for i in $(seq 1 5); do
    echo $i > hoge
    git add hoge
    git commit -m "Increment hoge to $i"
  done

  git reset --hard HEAD^

  git checkout -b work-1

  for i in $(seq 6 10); do
    echo $i > hoge
    git add hoge
    git commit -m "Increment hoge to $i"
  done

  git checkout master
  git merge work-1

  git reflog master
)

rm -rf $workspace
