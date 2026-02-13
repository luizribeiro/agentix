{ nixpkgs, system, module }:

let
  pkgs = import nixpkgs {
    inherit system;
  };

  lib = pkgs.lib;

  hostDefaultArch =
    if pkgs.stdenv.hostPlatform.isAarch64 then
      "aarch64"
    else
      "x86_64";

  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      module
      {
        virtualisation.gondolin.guest.enable = true;
      }
    ];
  };

  cfg = nixos.config.virtualisation.gondolin.guest;

  _ = assert cfg.enable;
    assert cfg.arch == hostDefaultArch;
    assert cfg.rootfsLabel == "gondolin-root";
    assert cfg.includeOpenSSH;
    assert cfg.extraPackages == [ ];
    assert cfg.diskSizeMb == null;
    true;
in
pkgs.runCommand "gondolin-module-eval" { } ''
  echo "gondolin guest module options evaluate correctly" > "$out"
''
