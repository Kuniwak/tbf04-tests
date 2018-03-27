#!/bin/bash -eux
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

    git fsck

    mv $packfile ./pack
    git unpack-objects < ./pack
    rmtrash ./pack

    tree=$(git cat-file -p HEAD^^ | head -1 | sed -e 's/^tree //')
    tree_file=$(echo $tree | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm  $tree_file

    git fsck || true

    commit=$(git fsck | grep 'broken link' | sed -e 's/broken link from  commit \(.*\)/\1/' || true)
    broken_tree=$(git fsck | grep 'missing tree' | sed -e 's/missing tree \(.*\)/\1/' || true)
    parent_tree=$(git rev-parse $commit^^{tree})

    git replace -f $broken_tree $parent_tree
    git cat-file -p $broken_tree

    git filter-branch --tree-filter true -- --all

    git fsck || true

    git replace -d $broken_tree

    commits=$(git rev-list --all)
    for commit in $commits; do
      if ! git rev-parse $commit^{tree}; then
        commit_file=$(echo $commit | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
        rm $commit_file
      fi
    done

    for commit in $commits; do
      if ! git rev-list $commit; then
        commit_file=$(echo $commit | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
        if [[ -f $commit_file ]]; then
          rm $commit_file
        fi
      fi
    done

    git fsck || true

    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
    git reflog expire --stale-fix --all

    git fsck
  )
)

rmtrash $workspace
