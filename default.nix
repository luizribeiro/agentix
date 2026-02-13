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

  gondolinHelpers = import ./lib/gondolin-helpers.nix {
    lib = nixpkgsLib;
    inherit nixosSystem overlay gondolinGuestModule;
  };
in
{
  inherit overlay;

  overlays.default = overlay;

  nixosModules = {
    gondolin-guest = gondolinGuestModule;
  };

  lib = gondolinHelpers;
}
