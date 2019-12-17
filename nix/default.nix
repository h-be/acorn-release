{ holonix }:
{
 buildInputs = []
 ++ ( holonix.pkgs.callPackage ./acorn { pkgs = holonix.pkgs; } ).buildInputs
 ++ ( holonix.pkgs.callPackage ./holochain { pkgs = holonix.pkgs; } ).buildInputs;
}
