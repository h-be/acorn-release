#!/usr/bin/env bash
set -euxo pipefail
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"
./clean.sh
rm -rf ./ui
rm -rf ./dna
rm -rf ./Acorn-*
rm -rf $HOME/.config/Acorn
rm -rf ./node_modules
