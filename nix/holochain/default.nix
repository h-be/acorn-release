{ pkgs }:
let
  script = pkgs.writeShellScriptBin "acorn-release"
  ''
  set -euxo pipefail
  ./update-dna-version.sh
  ./update-ui-version.sh
  '';
in
{
 buildInputs = [ script ];
}
