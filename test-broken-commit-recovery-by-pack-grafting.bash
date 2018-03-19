#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./broken-commit.XXXXXX)

(cd $WORKSPACE
  mkdir remote

  (cd remote
    git init
    echo a > a
    echo b > b
    echo c > c

    export GIT_AUTHOR_DATE='1521450633 +0900'
    export GIT_COMMITTER_DATE='1521450633 +0900'
    git add a
    git commit -m "Add a"

    export GIT_AUTHOR_DATE='1521450693 +0900'
    export GIT_COMMITTER_DATE='1521450693 +0900'
    git add b
    git commit -m "Add b"

    export GIT_AUTHOR_DATE='1521450753 +0900'
    export GIT_COMMITTER_DATE='1521450753 +0900'
    git add c
    git commit -m "Add c"
  )

  git clone ./remote ./broken --no-local
  (cd broken
    PACKFILE=$(find .git/objects/pack -name 'pack-*.pack')
    echo d > d

    export GIT_AUTHOR_DATE='1521450753 +0900'
    export GIT_COMMITTER_DATE='1521450753 +0900'
    git add d
    git commit -m "Add d"

    COMMIT=$(git rev-parse HEAD^^)

    git cat-file -p $COMMIT

    git fsck

    mv $PACKFILE ./pack
    git unpack-objects < ./pack
    rmtrash ./pack

    COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $COMMIT_FILE

    git log || true
    git fsck || true
  )

  git clone ./remote ./re-cloned --no-local
  ALTER_PACKFILE=$(find re-cloned/.git/objects/pack -name 'pack-*.pack')
  PACKFILE_BASENAME=$(basename $ALTER_PACKFILE)
  mv $ALTER_PACKFILE ./broken/.git/objects/pack/$PACKFILE_BASENAME

  (cd ./broken
    git fsck && echo OK || echo NG
  )
)

rmtrash $WORKSPACE
