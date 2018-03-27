#!/bin/sh -eux
set -o pipefail

workspace=$(mktemp -d ./rebase-orig-head-recovery.XXXXXX)

(cd $workspace
  git init
  echo a > a
  echo b > b
	echo c > c
  git add a
  git commit -m "Add a"

  git add b
  git commit -m "Add b"

  git checkout -b branch-c HEAD@{1}

	git add c
	git commit -m "Add c"

	git rebase master
	git log --oneline
	git show ORIG_HEAD
)

rm -rf $workspace
