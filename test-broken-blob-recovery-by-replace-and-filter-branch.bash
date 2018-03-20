#!/bin/bash -eux
set -o pipefail


WORKSPACE=$(mktemp -d ./broken-blob.XXXXXX)

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

    COMMIT=$(git rev-parse HEAD^^)
    TREE=$(git rev-parse $COMMIT^{tree})
    BLOB=$(git cat-file -p $TREE | grep blob | head -1 | sed -e 's/^[0-9]* [a-z]* \([0-9a-f]*\).*/\1/')
    BLOB_FILE=$(echo $BLOB | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $BLOB_FILE

    git fsck || true

    NEW_BLOB=$(echo "このblobは壊れました（注: 完全な復元はできませんでした）" | git hash-object -t blob --stdin -w)

    git replace -f $BLOB $NEW_BLOB
    git cat-file -p $BLOB

    git filter-branch --tree-filter true -- --all

    git replace -d $BLOB
    git show HEAD^^:a
  )

  git clone ./broken ./repaired
  (cd ./repaired
    git fsck
  )
)

rmtrash $WORKSPACE
