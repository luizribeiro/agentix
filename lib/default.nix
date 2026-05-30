{ lib
, nixosSystem
}:
let
  # Auto-discover every subdirectory of packages/ that has a default.nix.
  # Each package self-contains its dependencies; no per-package overrides
  # live here.
  packagesDir = ../packages;
  packageNames = lib.attrNames (
    lib.filterAttrs
      (name: type: type == "directory"
        && builtins.pathExists (packagesDir + "/${name}/default.nix"))
      (builtins.readDir packagesDir)
  );

  overlay = final: prev:
    lib.genAttrs packageNames (name:
      final.callPackage (packagesDir + "/${name}") { }
    );
in
{
  inherit overlay;
}
