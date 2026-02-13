{ nixpkgs ? <nixpkgs> }:
let
  nixpkgsLib = (import nixpkgs { }).lib;
  nixosSystem = args: import (nixpkgs + "/nixos/lib/eval-config.nix") ({
    lib = nixpkgsLib;
  } // args);

  overlay = final: prev:
    {
      codex-cli = final.callPackage ./packages/codex-cli { };
      claude-code = final.callPackage ./packages/claude-code { };
      gemini-cli = final.callPackage ./packages/gemini-cli { };
      crush = final.callPackage ./packages/crush { };
      opencode = final.callPackage ./packages/opencode { };
      pi = final.callPackage ./packages/pi { };
      gondolin = final.callPackage ./packages/gondolin { };
    }
    // prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
      gondolin-guest-bins = final.callPackage ./packages/gondolin-guest-bins { };
    };

  gondolinGuestModule = import ./modules/gondolin/guest.nix;

  defaultGuestArchForSystem = system:
    if nixpkgsLib.hasPrefix "aarch64" system then
      "aarch64"
    else
      "x86_64";

  mkGondolinGuestSystem =
    { system
    , modules ? [ ]
    , specialArgs ? { }
    , arch ? defaultGuestArchForSystem system
    , rootfsLabel ? "gondolin-root"
    , includeOpenSSH ? true
    , extraPackages ? [ ]
    , diskSizeMb ? null
    , stateVersion ? "25.11"
    }:
    nixosSystem {
      inherit system specialArgs;
      modules = [
        gondolinGuestModule
        ({ ... }: {
          nixpkgs.overlays = [ overlay ];

          virtualisation.gondolin.guest = {
            enable = true;
            inherit arch rootfsLabel includeOpenSSH extraPackages diskSizeMb;
          };

          fileSystems."/" = {
            device = "/dev/disk/by-label/${rootfsLabel}";
            fsType = "ext4";
          };

          boot.loader.grub.devices = [ "/dev/vda" ];
          system.stateVersion = stateVersion;
        })
      ] ++ modules;
    };

  mkGondolinAssets =
    { guestSystem ? null
    , system ? null
    , ...
    }@args:
    let
      resolvedGuestSystem =
        if guestSystem != null then
          guestSystem
        else if system != null then
          mkGondolinGuestSystem (builtins.removeAttrs args [ "guestSystem" ])
        else
          throw "mkGondolinAssets requires either guestSystem or system";
    in
    resolvedGuestSystem.config.system.build.gondolinAssets;

  mkGondolinWithAssets =
    { pkgs
    , assets
    , name ? "gondolin-with-assets"
    }:
    pkgs.writeShellScriptBin name ''
      export GONDOLIN_GUEST_DIR=${assets}
      exec ${pkgs.gondolin}/bin/gondolin "$@"
    '';
in
{
  inherit overlay;

  overlays.default = overlay;

  nixosModules = {
    gondolin-guest = gondolinGuestModule;
  };

  lib = {
    inherit
      defaultGuestArchForSystem
      mkGondolinGuestSystem
      mkGondolinAssets
      mkGondolinWithAssets
      ;
  };
}
