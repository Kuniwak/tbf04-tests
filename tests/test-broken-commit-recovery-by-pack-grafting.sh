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

    git log || true
    git fsck || true
  )

  git clone ./remote ./re-cloned --no-local
  alter_packfile=$(find re-cloned/.git/objects/pack -name 'pack-*.pack')
  packfile_basename=$(basename $alter_packfile)
  mv $alter_packfile ./broken/.git/objects/pack/$packfile_basename

  (cd ./broken
    git fsck && echo OK || echo NG
  )
)

rm -rf $workspace
