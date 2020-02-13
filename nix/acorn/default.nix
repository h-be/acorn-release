{ pkgs }:
let
 bundle-dna = (pkgs.writeShellScriptBin "acorn-bundle-dna" ''
  rm -rf dna
  # an optional first argument should be the version number you want
  # default to 0.0.2, the first release
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.0.2}/acorn.dna.json"
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.0.2}/acorn.dna.json
  mkdir dna
  mv acorn.dna.json dna/acorn-hc.dna.json
  # hash the dna, and pipe the cleaned output into the gitignored dna_address file
  hc hash --path dna/acorn-hc.dna.json | awk '/DNA Hash: /{print $NF}' | tr -d '\n' > dna_address
 '');

 bundle-ui = (pkgs.writeShellScriptBin "acorn-bundle-ui" ''
  rm -rf acorn-ui
  rm -rf ui
  mkdir ui
  git clone --single-branch --branch=master --depth=1 https://github.com/h-be/acorn-ui.git

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
 '');

 clean = (pkgs.writeShellScriptBin "acorn-clean" ''
  set -euxo pipefail
  rm -rf ./acorn-ui
 '');

 reset = (pkgs.writeShellScriptBin "acorn-reset" ''
  set -euxo pipefail
  rm -rf ./ui
  rm -rf ./dna
  rm -rf ./Acorn-*
  rm -rf $HOME/.config/Acorn
  rm -rf ./node_modules
 '');

 pre-build = (pkgs.writeShellScriptBin "acorn-pre-build" ''
  ${pkgs.nodejs}/bin/npm install
  set -euxo pipefail
  ${clean}/bin/acorn-clean
 '');

 fetch-bins = (pkgs.writeShellScriptBin "acorn-fetch-bins" ''
  set -euxo pipefail
  echo 'fetching package-able holochain and hc binaries'
  echo 'this command expects apple-darwin or generic-linux-gnu to be passed as first argument'
  echo 'this command optionally can be passed holochain-rust tag as second argument'
  PLATFORM=''${1}
  VERSION=''${2:-v0.0.42-alpha5}
  HC=cli-$VERSION-x86_64-$PLATFORM.tar.gz
  HOLOCHAIN=holochain-$VERSION-x86_64-$PLATFORM.tar.gz
  curl -O -L https://github.com/holochain/holochain-rust/releases/download/$VERSION/$HC
  curl -O -L https://github.com/holochain/holochain-rust/releases/download/$VERSION/$HOLOCHAIN
  tar -xzvf $HC ./hc
  tar -xzvf $HOLOCHAIN ./holochain
  rm $HC
  rm $HOLOCHAIN
 '');

 build-linux = (pkgs.writeShellScriptBin "acorn-build-linux" ''
  ${pre-build}/bin/acorn-pre-build
  acorn_platform=''${1:-linux}
  acorn_arch=''${2:-x64}
  ${fetch-bins}/bin/acorn-fetch-bins generic-linux-gnu
  electron-packager . Acorn --platform=$acorn_platform --arch=$acorn_arch --overwrite --prune=true
  chmod +x ./Acorn-$acorn_platform-$acorn_arch/Acorn
 '');

 build-mac = (pkgs.writeShellScriptBin "acorn-build-mac" ''
  ${pre-build}/bin/acorn-pre-build
  ${fetch-bins}/bin/acorn-fetch-bins apple-darwin
  electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\" --osx-sign.hardenedRuntime=true --osx-sign.gatekeeperAssess=false --osx-sign.entitlements=entitlements.mac.plist --osx-sign.entitlements-inherit=entitlements.mac.plist --osx-sign.type=distribution --osx-sign.identity=\"$APPLE_DEV_IDENTITY\" --osx-notarize.apple-id=\"$APPLE_ID_EMAIL\" --osx-notarize.apple-id-password=\"$APPLE_ID_PASSWORD\"
 '');

 build-mac-unsigned = (pkgs.writeShellScriptBin "acorn-build-mac-unsigned" ''
  ${pre-build}/bin/acorn-pre-build
  ${fetch-bins}/bin/acorn-fetch-bins apple-darwin
  # electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\"
 '');

 acorn = (pkgs.writeShellScriptBin "acorn" ''
  ${pkgs.nodejs}/bin/npm install
  ${pkgs.electron_6}/bin/electron .
 '');
in
{
 buildInputs = [
  bundle-dna
  bundle-ui
  clean
  reset
  build-linux
  build-mac
  build-mac-unsigned
  acorn
 ];
}
