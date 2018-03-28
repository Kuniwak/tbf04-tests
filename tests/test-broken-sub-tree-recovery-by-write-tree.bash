#!/bin/bash -eu
set -o pipefail


workspace=$(mktemp -d ./broken-tree.XXXXXX)

(cd $workspace
  mkdir remote

  (cd remote
    git init
    echo a > a
    mkdir -p b/b
    echo b > b/b/b

    export GIT_AUTHOR_DATE='1521450633 +0900'
    export GIT_COMMITTER_DATE='1521450633 +0900'
    git add a
    git commit -m "Add a"

    export GIT_AUTHOR_DATE='1521450693 +0900'
    export GIT_COMMITTER_DATE='1521450693 +0900'
    git add b/b/b
    git commit -m "Add b"
  )

  git clone ./remote ./broken --no-local
  (cd broken
    packfile=$(find .git/objects/pack -name 'pack-*.pack')
    echo c > c

    export GIT_AUTHOR_DATE='1521450753 +0900'
    export GIT_COMMITTER_DATE='1521450753 +0900'
    git add c
    git commit -m "Add c"

    commit=$(git rev-parse HEAD^)

    git cat-file -p $commit

    git fsck

    mv $packfile ./pack
    git unpack-objects < ./pack
    rm -f ./pack

    tree=$(git rev-parse HEAD^^{tree})
    subtree=$(git ls-tree $tree | grep tree | sed -e 's/^[0-9]* tree \([0-9a-f]*\).*/\1/')
    subsubtree=$(git ls-tree $subtree | grep tree | sed -e 's/^[0-9]* tree \([0-9a-f]*\).*/\1/')
    subsubtree_file=$(echo $subsubtree | sed -e 's/\(..\)\(.*\)/.git\/objects\/\1\/\2/')
    rm -f  $subsubtree_file

    git fsck || true

    missing=$(git fsck | grep missing | sed -e 's/missing tree \(.*\)/\1/' || true)

    for ref in $(git rev-list --all); do
      git rev-parse --verify $ref^0 > /dev/null 2>&1 && echo $(git rev-parse $ref^0)
    done > $committishes

    walk() {
      target=$1
      tree=$2
      current=$3

      if git ls-tree $tree > ls-tree-result 2> /dev/null; then
        while read mode type sha1 basename; do
          if [[ $sha1 = $target ]]; then
            echo "$current/$basename"
          fi

          if [[ $type = tree ]]; then
            walk $target $sha1 "$current/$basename"
          fi
        done < ls-tree-result
      fi
    }

    committishes=$(mktemp committishes.XXXXXX)
    path_candidates=$(mktemp path-candidates.XXXXXX)

    for committish in $(cat $committishes); do
      if git rev-parse --verify $commit^{tree} > /dev/null 2>&1; then
        tree=$(git rev-parse $commit^{tree})
        walk $missing $tree .
      fi
    done | sort | uniq > $path_candidates

    log=$(mktemp log.XXXXXX)
    for path_candidate in $(cat $path_candidates); do
      for committish in $(cat $committishes); do
        if git rev-parse --verify $committish:$path_candidate > /dev/null 2>&1; then
          author_date=$(git cat-file -p $committish | grep '^author' | sed -e 's/^author .* \([0-9]*\) +[0-9]*/\1/')
          echo "$author_date $committish $path_candidate"
        else
          if [[ $(git rev-parse $committish^{tree} --verify ) ]]; then
            git show $committish --no-patch --format="%at %H (nothing or broken)"
          fi
        fi
      done | sort
    done
  )
)

rmtrash $workspace
