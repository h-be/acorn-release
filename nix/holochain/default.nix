{ pkgs }:
let
  script = pkgs.writeShellScriptBin "acorn-release"
  ''
  set -euxo pipefail
  ./update-dna-version.sh
  ./update-ui-version.sh
  ./clean.sh
  npm run build-mac-no-sign
  '';
in
{
 buildInputs = [ script ];
}
