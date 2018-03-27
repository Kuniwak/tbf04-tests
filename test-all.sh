#!/bin/sh -eu

base_dir=$(cd $(dirname $0); pwd)

for test in $(find ./tests -type f); do
  $test && echo -e "OK: $test\n\n" || echo -e "NG: $test\n\n"
done
