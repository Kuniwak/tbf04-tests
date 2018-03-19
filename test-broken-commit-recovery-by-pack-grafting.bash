#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./broken-commit.XXXXXX)

(cd $WORKSPACE
  mkdir remote

  (cd remote
    git init

    echo a > a
    echo c > c
    echo d > d

    git add a
    git commit -m "Add a"

    git checkout -b branch-b

    git add c
    git commit -m "Add c"

    git add d
    git commit -m "Add d"

    git checkout master
  )

  git clone ./remote ./broken --no-local
  (cd broken
    PACKFILE=$(find .git/objects/pack -name 'pack-*.pack')
    echo b > b
    mkdir e
    echo e > e/e

    git add b
    git commit -m "Add b"

    git add e/e
    git commit -m "Add e"

    COMMIT=$(git rev-parse HEAD^^)
    COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')

    git cat-file -p $COMMIT

    git fsck

    mv $PACKFILE ./pack
    git unpack-objects < ./pack
    rmtrash ./pack

    chmod +w $COMMIT_FILE
    echo > $COMMIT_FILE
    chmod -x $COMMIT_FILE

    git rev-list --all || true

		set +e
    git fsck
		echo $?
		set -e
  )

  git clone ./remote ./re-cloned --no-local
  ALTER_PACKFILE=$(find re-cloned/.git/objects/pack -name 'pack-*.pack')
  PACKFILE_BASENAME=$(basename $ALTER_PACKFILE)
  mv $ALTER_PACKFILE ./broken/.git/objects/pack/$PACKFILE_BASENAME

  (cd ./broken
    git rev-list --all
    git gc
    git fsck
  )
)

rmtrash $WORKSPACE
