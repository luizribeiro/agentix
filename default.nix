{ nixpkgs ? <nixpkgs> }:
let
  nixpkgsLib = (import nixpkgs { }).lib;
  nixosSystem = args: import (nixpkgs + "/nixos/lib/eval-config.nix") ({
    lib = nixpkgsLib;
  } // args);

  agentixLib = import ./lib {
    lib = nixpkgsLib;
    inherit nixosSystem;
  };
in
{
  inherit (agentixLib) overlay;

  overlays.default = agentixLib.overlay;

  nixosModules = {
    gondolin-guest = agentixLib.gondolinGuestModule;
  };

  lib = agentixLib.gondolinHelpers;
}
