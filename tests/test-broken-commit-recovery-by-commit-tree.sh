#!/bin/sh -eux
set -o pipefail


workspace=$(mktemp -d ./broken-commit.XXXXXX)

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

    commit_file=$(echo $commit | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm -f $commit_file

    git fsck || true

    broken_child=$(git fsck | grep 'broken' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    broken_parent=$(git fsck | grep 'dangling commit' | sed -e 's/dangling commit \(.*\)/\1/' || true)
    broken_tree=$(git fsck | grep 'dangling tree' | sed -e 's/dangling tree \(.*\)/\1/' || true)

    git cat-file -p $broken_parent
    git cat-file -p $broken_child

    broken_parent_tree=$(git log -1 --format=%T $broken_parent)
    git diff $broken_parent_tree $broken_tree

    export GIT_AUTHOR_NAME='Kuniwak'
    export GIT_AUTHOR_EMAIL='orga.chem.job@gmail.com'
    export GIT_COMMITTER_NAME='Kuniwak'
    export GIT_COMMITTER_EMAIL='orga.chem.job@gmail.com'

    for time in $(seq -f '%f' 1521450633  1521450753 | sed -e 's/\([^.]*\).*/\1/'); do
      export GIT_AUTHOR_DATE="$time +0900"
      export GIT_COMMITTER_DATE="$time +0900"

      git commit-tree $broken_tree -p $broken_parent -m 'Add b'
    done
  )

  git fsck
)

rm -rf $workspace
