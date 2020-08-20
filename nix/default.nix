{ holonix, config }:
{
 buildInputs = []
 ++ ( holonix.pkgs.callPackage ./acorn { pkgs = holonix.pkgs; config = config; } ).buildInputs;
}
