#!/usr/bin/env bash
set -euxo pipefail
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"
rm -rf ./acorn-ui
rm -rf ./acorn-hc
rm -rf ./ui
rm -rf ./dna
rm -rf ./Acorn-*
rm -rf $HOME/.config/Acorn
rm -rf ./node_modules
