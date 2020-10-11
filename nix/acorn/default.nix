{ pkgs, config }:
let
 bundle-dna = (pkgs.writeShellScriptBin "acorn-bundle-dna" ''
  rm -rf dna
  # an optional first argument should be the version number you want
  # default to 0.4.0
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.4.0}/profiles.dna.gz"
  echo "fetching DNA from https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.4.0}/projects.dna.gz"
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.4.0}/profiles.dna.gz
  curl -O -L https://github.com/h-be/acorn-hc/releases/download/v''${1:-0.4.0}/projects.dna.gz
  mkdir dna
  mv profiles.dna.gz dna/profiles.dna.gz
  mv projects.dna.gz dna/projects.dna.gz
 '');

 bundle-ui = (pkgs.writeShellScriptBin "acorn-bundle-ui" ''
  rm -rf ui
  mkdir ui
  # an optional first argument should be the version number you want
  # default to 0.4.1
  curl -O -L https://github.com/h-be/acorn-ui/releases/download/v''${1:-0.4.1}/acorn-ui.zip
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

 build-linux = (pkgs.writeShellScriptBin "acorn-build-linux" ''
  ${pre-build}/bin/acorn-pre-build
  acorn_platform=''${1:-linux}
  acorn_arch=''${2:-x64}
  electron-packager . Acorn --platform=$acorn_platform --arch=$acorn_arch --overwrite --prune=true
  chmod +x ./Acorn-$acorn_platform-$acorn_arch/Acorn
 '');

 build-mac = (pkgs.writeShellScriptBin "acorn-build-mac" ''
  ${pre-build}/bin/acorn-pre-build
  electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\" --osx-sign.hardenedRuntime=true --osx-sign.gatekeeperAssess=false --osx-sign.entitlements=entitlements.mac.plist --osx-sign.entitlements-inherit=entitlements.mac.plist --osx-sign.type=distribution --osx-sign.identity=\"$APPLE_DEV_IDENTITY\" --osx-notarize.apple-id=\"$APPLE_ID_EMAIL\" --osx-notarize.apple-id-password=\"$APPLE_ID_PASSWORD\"
 '');

 build-mac-unsigned = (pkgs.writeShellScriptBin "acorn-build-mac-unsigned" ''
  ${pre-build}/bin/acorn-pre-build
  electron-packager . Acorn --platform=darwin --arch=x64 --overwrite --prune=true --icon=\"ui/logo/acorn-logo-desktop-512px@2x.icns\"
 '');

 acorn = (pkgs.writeShellScriptBin "acorn" ''
  ${pkgs.nodejs}/bin/npm install
  ${pkgs.electron_6}/bin/electron .
 '');
 
 tag = "v${config.release.version.current}";

 release-linux = pkgs.writeShellScriptBin "release-linux"
 ''
 set -euxo pipefail
 export zip_artifact='./?'
 export zip_artifact_name='?'
 export tag=''${CIRCLE_TAG:-${tag}}
 acorn-build-linux
 github-release upload --file "$zip_artifact" --owner ${config.release.github.owner} --repo ${config.release.github.repo} --tag $tag --name $zip_artifact_name --token $GITHUB_DEPLOY_TOKEN
 '';
 
in
{
 buildInputs = [
  bundle-dna
  bundle-ui
  reset
  build-linux
  build-mac
  build-mac-unsigned
  release-linux
  acorn
 ];
}
