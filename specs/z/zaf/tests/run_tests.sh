#!/bin/bash

set -e

gcc -Wall test-hyphen.c -o test-hyphen -lhyphen

echo "Test to hyphenate given word => woordafbreking"
echo "woordafbreking" | ./test-hyphen /usr/share/hyphen/hyph_af_ZA.dic /dev/stdin

echo ""
echo ""

echo "Test to give all possible ways to hyphenate the given word => woordafbreking"
echo ""woordafbreking | ./test-hyphen -d /usr/share/hyphen/hyph_af_ZA.dic /dev/stdin

