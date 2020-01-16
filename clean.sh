#!/usr/bin/env bash
set -euxo pipefail
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"
rm -rf ./acorn-ui
rm -rf ./acorn-hc
