#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"
rm keystore.key
rm conductor-config.toml
rm -rf ./storage
rm -rf ./acorn-ui
rm -rf ./acorn-hc
