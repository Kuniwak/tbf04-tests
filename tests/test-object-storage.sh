#!/bin/sh -eux
set -o pipefail


workspace=$(mktemp -d ./object-storage.XXXXXX)

(cd $workspace
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

  find .git/objects -type file

  commit=$(git rev-parse HEAD)
  tree=$(git cat-file -p HEAD | head -1 | sed -e 's/^tree //')
  blob=$(git cat-file -p $tree | head -1 | sed -e 's/^[0-9]* [a-z]* \([0-9a-f]*\).*/\1/')

  git cat-file -p $commit
  git cat-file -p $tree
  git cat-file -p $blob

  for object in $(find .git/objects -type file); do echo "$object 👈 $(git cat-file -t $(echo $object | sed -e 's/\.git\/objects\/\(..\)\/\(.*\)/\1\2/'))"; done

  git gc
  find .git/objects -type file

  git verify-pack -v $(find .git/objects/pack -name '*.idx' | head -1)
)

rm -rf $workspace
