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

    git fsck || true

    BROKEN_CHILD=$(git fsck | grep 'broken' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    BROKEN_PARENT=$(git fsck | grep 'dangling commit' | sed -e 's/dangling commit \(.*\)/\1/' || true)
    BROKEN_TREE=$(git fsck | grep 'dangling tree' | sed -e 's/dangling tree \(.*\)/\1/' || true)

    git cat-file -p $BROKEN_PARENT
    git cat-file -p $BROKEN_CHILD

    BROKEN_PARENT_TREE=$(git log -1 --format=%T $BROKEN_PARENT)
    git diff $BROKEN_PARENT_TREE $BROKEN_TREE

    export GIT_AUTHOR_NAME='Kuniwak'
    export GIT_AUTHOR_EMAIL='orga.chem.job@gmail.com'
    export GIT_COMMITTER_NAME='Kuniwak'
    export GIT_COMMITTER_EMAIL='orga.chem.job@gmail.com'
    for time in {1521450633..1521450753}; do
      export GIT_AUTHOR_DATE="$time +0900"
      export GIT_COMMITTER_DATE="$time +0900"

      git commit-tree $BROKEN_TREE -p $BROKEN_PARENT -m 'Add b'
    done
  )

  git fsck
)

rmtrash $WORKSPACE
