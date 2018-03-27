#!/bin/sh -eu
set -o pipefail

workspace=$(mktemp -d ./reset-branch-d-recovery.XXXXXX)

(cd $workspace
  mkdir origin
  (cd origin
    git init

    echo a > a
    echo b > b
    echo c > c
    echo c > .gitignore

    git add a .gitignore
    git commit -m "Add a"

    git status
  )

  git clone ./origin clone
  (cd clone
    ls
    git ls-files
  )
)

rm -rf $workspace
