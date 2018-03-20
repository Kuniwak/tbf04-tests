#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./broken-tree.XXXXXX)

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

    TREE=$(git cat-file -p HEAD^^ | head -1 | sed -e 's/^tree //')
    TREE_FILE=$(echo $TREE | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $TREE_FILE

    git fsck || true

    COMMIT=$(git fsck | grep 'broken link' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    PARENTS=$(git rev-parse $COMMIT^@)
    CHILDREN=$(for CANDIDATE in $(git rev-list --all); do git rev-parse $CANDIDATE^@ | grep -q $COMMIT && echo $CANDIDATE || true; done)

    for PARENT in $PARENTS; do
      for CHILD in $CHILDREN; do
        git diff $PARENT..$CHILD

        git checkout $CHILDREN
        git reset HEAD
        git rm b
        git write-tree

        git reset HEAD
        git rm c
        git write-tree
      done
    done

    git fsck
  )
)

rmtrash $WORKSPACE
