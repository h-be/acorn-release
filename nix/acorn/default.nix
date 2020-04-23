{ pkgs }:
let
 bundle-dna = (pkgs.writeShellScriptBin "acorn-bundle-dna" ''
  rm -rf dnas
  # an optional first argument should be the version number you want
  # default to 0.3.1
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.2}/profiles.dna.json"
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.2}/projects.dna.json"
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.2}/profiles.dna.json
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.2}/projects.dna.json
  mkdir -p dnas/profiles/dist
  mkdir -p dnas/projects/dist
  mv profiles.dna.json dnas/profiles/dist/profiles.dna.json
  mv projects.dna.json dnas/projects/dist/projects.dna.json
  # hash the dna, and pipe the cleaned output into the gitignored dna_address file
  hc hash --path dnas/profiles/dist/profiles.dna.json | awk '/DNA Hash: /{print $NF}' | tr -d '\n' > dna_address
 '');

 bundle-ui = (pkgs.writeShellScriptBin "acorn-bundle-ui" ''
  rm -rf acorn-ui
  rm -rf ui
  mkdir ui
  git clone --single-branch --branch=holoscape-support --depth=1 https://github.com/h-be/acorn-ui.git

  # ui
  cd acorn-ui
  npm install
  npm run build-holoscape
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
  rm -rf ./dnas
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
  VERSION=''${2:-v0.0.47-alpha1}
  HC=cli-$VERSION-x86_64-$PLATFORM.tar.gz
  HOLOCHAIN=holochain-$VERSION-x86_64-$PLATFORM.tar.gz
  curl -O -L https://github.com/holochain/holochain-rust/releases/download/$VERSION/$HC
  curl -O -L https://github.com/holochain/holochain-rust/releases/download/$VERSION/$HOLOCHAIN
  tar -xzvf $HC ./hc
  tar -xzvf $HOLOCHAIN ./holochain
  rm $HC
  rm $HOLOCHAIN
 '');

 macos-fix-dylibs = (pkgs.writeShellScriptBin "acorn-macos-fix-dylibs" ''
  set -euxo pipefail
  echo 'fixing the dynamic linking of hc and holochain'
  echo 'based on: otool -L hc'
  install_name_tool -change /nix/store/qjf3nf4qa8q62giagjwdmdbjqni983km-Libsystem-osx-10.12.6/lib/libSystem.B.dylib /usr/lib/libSystem.B.dylib hc
  install_name_tool -change /nix/store/qnzg5xh5qw84gqrhh7aysycp92bxinms-pcre-8.43/lib/libpcre.1.dylib /usr/lib/libpcre.0.dylib hc
  install_name_tool -change /nix/store/qjf3nf4qa8q62giagjwdmdbjqni983km-Libsystem-osx-10.12.6/lib/libresolv.9.dylib /usr/lib/libresolv.9.dylib hc
  # note this is a slight hack, with unforeseen consequences?
  # because its a different lib? libiconv.dylib > libiconv.2.dylib
  install_name_tool -change /nix/store/cib1v4zhizcjwkr96753n87ssm3nsfkm-libiconv-osx-10.12.6/lib/libiconv.dylib /usr/lib/libiconv.2.dylib hc
  echo 'based on: otool -L holochain'
  install_name_tool -change /nix/store/qjf3nf4qa8q62giagjwdmdbjqni983km-Libsystem-osx-10.12.6/lib/libSystem.B.dylib /usr/lib/libSystem.B.dylib holochain
  install_name_tool -change /nix/store/qnzg5xh5qw84gqrhh7aysycp92bxinms-pcre-8.43/lib/libpcre.1.dylib /usr/lib/libpcre.0.dylib holochain
  install_name_tool -change /nix/store/qjf3nf4qa8q62giagjwdmdbjqni983km-Libsystem-osx-10.12.6/lib/libresolv.9.dylib /usr/lib/libresolv.9.dylib holochain
  # note this is a slight hack, with unforeseen consequences?
  # because its a different lib? libiconv.dylib > libiconv.2.dylib
  install_name_tool -change /nix/store/cib1v4zhizcjwkr96753n87ssm3nsfkm-libiconv-osx-10.12.6/lib/libiconv.dylib /usr/lib/libiconv.2.dylib holochain
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
  ${macos-fix-dylibs}/bin/acorn-macos-fix-dylibs
  electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\" --osx-sign.hardenedRuntime=true --osx-sign.gatekeeperAssess=false --osx-sign.entitlements=entitlements.mac.plist --osx-sign.entitlements-inherit=entitlements.mac.plist --osx-sign.type=distribution --osx-sign.identity=\"$APPLE_DEV_IDENTITY\" --osx-notarize.apple-id=\"$APPLE_ID_EMAIL\" --osx-notarize.apple-id-password=\"$APPLE_ID_PASSWORD\"
 '');

 build-mac-unsigned = (pkgs.writeShellScriptBin "acorn-build-mac-unsigned" ''
  ${pre-build}/bin/acorn-pre-build
  ${fetch-bins}/bin/acorn-fetch-bins apple-darwin
  ${macos-fix-dylibs}/bin/acorn-macos-fix-dylibs
  electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\"
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
  fetch-bins
  macos-fix-dylibs
  build-linux
  build-mac
  build-mac-unsigned
  acorn
 ];
}
