{ pkgs }:
let
 bundle-dna = (pkgs.writeShellScriptBin "acorn-bundle-dna" ''
  rm -rf dna
  # an optional first argument should be the version number you want
  # default to 0.3.5
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.5}/profiles.dna.json"
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.5}/projects.dna.json"
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.5}/profiles.dna.json
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.3.5}/projects.dna.json
  mkdir dna
  mv profiles.dna.json dna/profiles.dna.json
  mv projects.dna.json dna/projects.dna.json
  # hash the dna, and pipe the cleaned output into the gitignored profiles_dna_address file
  hc hash --path dna/profiles.dna.json | awk '/DNA Hash: /{print $NF}' | tr -d '\n' > profiles_dna_address
  # hash the dna, and pipe the cleaned output into the gitignored projects_dna_address file
  hc hash --path dna/projects.dna.json | awk '/DNA Hash: /{print $NF}' | tr -d '\n' > projects_dna_address
 '');

 bundle-ui = (pkgs.writeShellScriptBin "acorn-bundle-ui" ''
  rm -rf ui
  mkdir ui
  # an optional first argument should be the version number you want
  # default to 0.3.10
  curl -O -L https://github.com/h-be/acorn-ui/releases/download/v''${1:-0.3.10}/acorn-ui.zip
  # unzip into the ./ui folder
  unzip acorn-ui.zip -d ui
  rm acorn-ui.zip
 '');

 reset = (pkgs.writeShellScriptBin "acorn-reset" ''
  set -euxo pipefail
  rm -rf ./ui
  rm -rf ./dna
  rm -rf ./Acorn-*
  rm -rf $HOME/.config/Acorn
  rm -rf $HOME/Library/Application\ Support/Acorn
  rm -rf ./node_modules
 '');

 pre-build = (pkgs.writeShellScriptBin "acorn-pre-build" ''
  ${pkgs.nodejs}/bin/npm install
 '');

 fetch-bins = (pkgs.writeShellScriptBin "acorn-fetch-bins" ''
  set -euxo pipefail
  echo 'fetching package-able holochain and hc binaries'
  echo 'this command expects apple-darwin or generic-linux-gnu to be passed as first argument'
  echo 'this command optionally can be passed holochain-rust tag as second argument'
  PLATFORM=''${1}
  VERSION=''${2:-v0.0.51-alpha1}
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
  reset
  fetch-bins
  macos-fix-dylibs
  build-linux
  build-mac
  build-mac-unsigned
  acorn
 ];
}
