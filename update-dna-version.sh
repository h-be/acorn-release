#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

rm -rf acorn-hc
rm -rf dna
mkdir dna
git clone --depth=1 --branch update-hdk https://github.com/h-be/acorn-hc.git

# dna
# save the packaged DNA address to `dna_address`
node hc-package-and-save-address.js `which hc`
cp -R ./acorn-hc/dist/. ./dna/
