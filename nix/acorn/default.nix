{ pkgs }:
let
 update-deps = (pkgs.writeShellScriptBin "acorn-update-deps" ''
  ./update-dna-version.sh
  ./update-ui-version.sh
 '');

 clean = (pkgs.writeShellScriptBin "acorn-clean" ''
  ./clean.sh
 '');

 build = (pkgs.writeShellScriptBin "acorn-build" ''
  set -euxo pipefail
  acorn_platform=''${1:-linux}
  acorn_arch=''${2:-x64}
  ${update-deps}/bin/acorn-update-deps
  electron-packager . Acorn --platform=$acorn_platform --arch=$acorn_arch --overwrite
  chmod +x ./Acorn-$acorn_platform-$acorn_arch/Acorn
 '');

 acorn = (pkgs.writeShellScriptBin "acorn" ''
  ${update-deps}/bin/acorn-update-deps
  ${pkgs.electron_6}/bin/electron .
 '');
in
{
 buildInputs = [
  update-deps
  clean
  build
  acorn
 ];
}
