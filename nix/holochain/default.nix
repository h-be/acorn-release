{ pkgs }:
let
  script = pkgs.writeShellScriptBin "acorn-release"
  ''
  set -euxo pipefail
  ./clean.sh
  ./update-dna-version.sh
  ./update-ui-version.sh
  npm run build-mac-no-sign
  '';
in
{
 buildInputs = [ script ];
}
