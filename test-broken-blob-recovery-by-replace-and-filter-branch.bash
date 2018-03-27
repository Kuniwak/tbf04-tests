#!/bin/bash -eux
set -o pipefail


workspace=$(mktemp -d ./broken-blob.XXXXXX)

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

    git fsck

    mv $packfile ./pack
    git unpack-objects < ./pack
    rmtrash ./pack

    commit=$(git rev-parse HEAD^^)
    tree=$(git rev-parse $commit^{tree})
    blob=$(git cat-file -p $tree | grep blob | head -1 | sed -e 's/^[0-9]* [a-z]* \([0-9a-f]*\).*/\1/')
    blob_file=$(echo $blob | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $blob_file

    git fsck || true

    new_blob=$(echo "このblobは壊れました（注: 完全な復元はできませんでした）" | git hash-object -t blob --stdin -w)

    git replace -f $blob $new_blob
    git cat-file -p $blob

    git filter-branch --tree-filter true -- --all

    git replace -d $blob
    git show HEAD^^:a
  )

  git clone ./broken ./repaired
  (cd ./repaired
    git fsck
  )
)

rmtrash $workspace
