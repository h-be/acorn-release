#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

rm -rf acorn-hc
rm -rf dna
mkdir dna
git clone --depth=1 https://github.com/h-be/acorn-hc.git

# dna
# save the packaged DNA address to `dna_address`
node hc-package-and-save-address.js "$PWD/hc-linux"
cp -R ./acorn-hc/dist/. ./dna/
