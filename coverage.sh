#!/bin/sh
set -e
runner=$(mktemp)
crystal build --debug -o $runner $(find spec -name '*.cr' ! -name '*generator.cr')
rm -rf cov
kcov --include-path=src --path-strip-level=1 cov $runner
rm $runner
xdg-open cov/index.html
