#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

rm -rf acorn-ui
# rm -rf acorn-hc
rm -rf dna
mkdir dna
rm -rf ui
mkdir ui
git clone --single-branch --branch electron-fixes --depth=1 https://github.com/h-be/acorn-ui.git
# git clone --depth=1 https://github.com/h-be/acorn-hc.git

# we need to configure the hc-web-client initialization to
# use the right websocket URL
# this is necessary because we are serving a file that's normally served over
# http, as a file://, breaking the /dna_connections.json endpoint, which it
# would otherwise use
# sed -i -e 's/connect(connectOpts)/connect({ url: "ws:\/\/localhost:8888" })/g' ./acorn-ui/src/index.js

# dna
cd acorn-hc
hc package
cp -R ./dist/. ../dna/

# ui
cd ../acorn-ui
npm install
npm run build
cp -R ./dist/. ../ui/
