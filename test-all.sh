#!/bin/sh -eu

base_dir=$(cd $(dirname $0); pwd)
failed=0

for test in $(find ./tests -type f); do
	echo "BEGIN $test"
  if $test; then
    echo "OK: $test"
  else
    echo "NG: $test"
    failed=1
  fi
done

exit $failed
