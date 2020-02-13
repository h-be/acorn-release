{ holonix }:
{
 buildInputs = []
 ++ ( holonix.pkgs.callPackage ./acorn { pkgs = holonix.pkgs; } ).buildInputs;
}
