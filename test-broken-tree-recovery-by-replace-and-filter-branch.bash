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

    git fsck

    mv $PACKFILE ./pack
    git unpack-objects < ./pack
    rmtrash ./pack

    TREE=$(git cat-file -p HEAD^^ | head -1 | sed -e 's/^tree //')
    TREE_FILE=$(echo $TREE | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $TREE_FILE

    git fsck || true

    COMMIT=$(git fsck | grep 'broken link' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    BROKEN_TREE=$(git fsck | grep 'missing tree' | sed -e 's/missing tree \(.*\)/\1/' || true)
    PARENT_TREE=$(git rev-parse $COMMIT^^{tree})

    git replace -f $BROKEN_TREE $PARENT_TREE
    git cat-file -p $BROKEN_TREE

    git filter-branch --tree-filter true -- --all

    git fsck || true

    git replace -d $BROKEN_TREE

    COMMITS=$(git rev-list --all)
    for COMMIT in $COMMITS; do
      if ! git rev-parse $COMMIT^{tree}; then
        COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
        rm $COMMIT_FILE
      fi
    done

    for COMMIT in $COMMITS; do
      if ! git rev-list $COMMIT; then
        COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
        if [[ -f $COMMIT_FILE ]]; then
          rm $COMMIT_FILE
        fi
      fi
    done

    git fsck || true

    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
    git reflog expire --stale-fix --all

    git fsck
  )
)

rmtrash $WORKSPACE
