#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

rm -rf acorn-ui
rm -rf ui
mkdir ui
git clone --single-branch --depth=1 https://github.com/h-be/acorn-ui.git

# we need to configure the hc-web-client initialization to
# use the right websocket URL
# this is necessary because we are serving a file that's normally served over
# http, as a file://, breaking the /dna_connections.json endpoint, which it
# would otherwise use
sed -i -e 's/connect(connectOpts)/connect({ url: "ws:\/\/localhost:8889" })/g' ./acorn-ui/src/index.js

# ui
cd acorn-ui
npm install
npm run build
cd ..
# copy all files from the acorn-ui/dist folder into the main ./ui folder
cp -R ./acorn-ui/dist/. ./ui/
