#!/bin/sh -eux
set -o pipefail


workspace=$(mktemp -d ./broken-tree.XXXXXX)

(cd $workspace
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
    packfile=$(find .git/objects/pack -name 'pack-*.pack')
    echo d > d

    export GIT_AUTHOR_DATE='1521450753 +0900'
    export GIT_COMMITTER_DATE='1521450753 +0900'
    git add d
    git commit -m "Add d"

    commit=$(git rev-parse HEAD^^)

    git cat-file -p $commit

    git fsck

    mv $packfile ./pack
    git unpack-objects < ./pack
    rm -f ./pack

    tree=$(git cat-file -p HEAD^^ | head -1 | sed -e 's/^tree //')
    tree_file=$(echo $tree | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm -f $tree_file

    git fsck || true

    commit=$(git fsck | grep 'broken link' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    parents=$(git rev-parse $commit^@)
    children=$(for candidate in $(git rev-list --all); do git rev-parse $candidate^@ | grep -q $commit && echo $candidate || true; done)

    for parent in $parents; do
      for child in $children; do
        git diff $parent..$child

        git checkout $children
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

rm -rf $workspace
