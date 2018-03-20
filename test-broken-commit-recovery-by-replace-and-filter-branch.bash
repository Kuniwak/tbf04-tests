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

    git checkout -b branch-x
    echo x > x
    git add x
    git commit -m "Add x"

    git checkout master
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

    git rev-list --all || true
    git fsck || true

    BROKEN=$(git fsck | grep 'missing commit' | sed -e 's/missing commit \(.*\)/\1/' || true)
    BROKEN_PARENT=$(git fsck | grep 'dangling commit' | sed -e 's/dangling commit \(.*\)/\1/' || true)
    BROKEN_TREE=$(git fsck | grep 'dangling tree' | sed -e 's/dangling tree \(.*\)/\1/' || true)
    REPAIRED_COMMIT=$(git commit-tree $BROKEN_TREE -p $BROKEN_PARENT -m "壊れたcommitを修復（注: 完全な修復はできませんでした）")

    git replace -f $BROKEN $REPAIRED_COMMIT

    git show $BROKEN

    git filter-branch -- --all

    git rev-list --all
    git fsck || true

    COMMITS=$(git rev-list --all)
    git replace -d 6cfd886dd9ab8c040dcb473d51ef4293f006a2a3

    for COMMIT in $COMMITS; do
      if ! git rev-list $COMMIT; then
        COMMIT_FILE=$(echo $COMMIT | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
        rmtrash $COMMIT_FILE
      fi
    done

    git fsck || true

    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
    git reflog expire --stale-fix --all
    git fsck
  )
)

rmtrash $WORKSPACE
