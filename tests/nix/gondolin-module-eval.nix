{ nixpkgs, system, module }:

let
  overlay = final: prev: {
    gondolin-guest-bins = final.callPackage ../../packages/gondolin-guest-bins { };
  };

  pkgs = import nixpkgs {
    inherit system;
    overlays = [ overlay ];
  };

  lib = pkgs.lib;

  hostDefaultArch =
    if pkgs.stdenv.hostPlatform.isAarch64 then
      "aarch64"
    else
      "x86_64";

  baseGuestModule = {
    nixpkgs.pkgs = pkgs;

    fileSystems."/" = {
      device = "/dev/disk/by-label/gondolin-root";
      fsType = "ext4";
    };

    boot.loader.grub.devices = [ "/dev/vda" ];
    system.stateVersion = "25.11";
  };

  nixos = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      module
      baseGuestModule
      {
        virtualisation.gondolin.guest.enable = true;
      }
    ];
  };

  nixosNoSsh = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      module
      baseGuestModule
      {
        virtualisation.gondolin.guest = {
          enable = true;
          includeOpenSSH = false;
        };
      }
    ];
  };

  nixosSized = nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      module
      baseGuestModule
      {
        virtualisation.gondolin.guest = {
          enable = true;
          rootfsLabel = "gondolin-custom";
          diskSizeMb = 3072;
          includeOpenSSH = true;
        };
      }
    ];
  };

  cfg = nixos.config.virtualisation.gondolin.guest;
  cfgNoSsh = nixosNoSsh.config.virtualisation.gondolin.guest;

  conflictingSshd = builtins.tryEval (
    (nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        module
        baseGuestModule
        {
          virtualisation.gondolin.guest.enable = true;
          virtualisation.gondolin.guest.includeOpenSSH = true;
          services.openssh.enable = true;
        }
      ];
    }).config.system.build.toplevel
  );

  tmpfilesRules = nixos.config.systemd.tmpfiles.rules;
  tmpfilesRulesNoSsh = nixosNoSsh.config.systemd.tmpfiles.rules;

  systemPackages = nixos.config.environment.systemPackages;
  systemPackagesNoSsh = nixosNoSsh.config.environment.systemPackages;

  sandboxService = nixos.config.systemd.services.gondolin-sandbox-stack;
in
assert cfg.enable;
assert cfg.arch == hostDefaultArch;
assert cfg.rootfsLabel == "gondolin-root";
assert cfg.includeOpenSSH;
assert cfg.diskSizeMb == null;
assert cfgNoSsh.enable;
assert !cfgNoSsh.includeOpenSSH;
assert lib.elem pkgs.gondolin-guest-bins systemPackages;
assert lib.elem pkgs.bashInteractive systemPackages;
assert lib.elem pkgs.gondolin-guest-bins systemPackagesNoSsh;
assert lib.elem pkgs.bashInteractive systemPackagesNoSsh;
assert !conflictingSshd.success;
assert lib.elem "L+ /bin/sh - - - - /run/current-system/sw/bin/sh" tmpfilesRules;
assert lib.elem "L+ /bin/bash - - - - /run/current-system/sw/bin/bash" tmpfilesRules;
assert lib.elem "L+ /usr/sbin/sshd - - - - /run/current-system/sw/bin/sshd" tmpfilesRules;
assert !(lib.elem "L+ /usr/sbin/sshd - - - - /run/current-system/sw/bin/sshd" tmpfilesRulesNoSsh);
assert sandboxService.wantedBy == [ "multi-user.target" ];
assert sandboxService.serviceConfig.Restart == "on-failure";
assert lib.hasInfix "gondolin-sandbox-stack" sandboxService.serviceConfig.ExecStart;
assert lib.isDerivation nixos.config.system.build.gondolinAssets;
pkgs.runCommand "gondolin-module-eval" { nativeBuildInputs = [ pkgs.jq ]; } ''
  set -euo pipefail

  default_manifest="${nixos.config.system.build.gondolinAssets}/manifest.json"
  no_ssh_manifest="${nixosNoSsh.config.system.build.gondolinAssets}/manifest.json"
  sized_manifest="${nixosSized.config.system.build.gondolinAssets}/manifest.json"

  test "$(jq -r '.config.arch' "$default_manifest")" = "${hostDefaultArch}"
  test "$(jq -r '.config.rootfsLabel' "$default_manifest")" = "gondolin-root"
  test "$(jq -r '.config.includeOpenSSH' "$default_manifest")" = "true"
  test "$(jq -r '.config | has("diskSizeMb")' "$default_manifest")" = "false"

  test "$(jq -r '.config.includeOpenSSH' "$no_ssh_manifest")" = "false"
  test "$(jq -r '.config | has("diskSizeMb")' "$no_ssh_manifest")" = "false"

  test "$(jq -r '.config.arch' "$sized_manifest")" = "${hostDefaultArch}"
  test "$(jq -r '.config.rootfsLabel' "$sized_manifest")" = "gondolin-custom"
  test "$(jq -r '.config.diskSizeMb' "$sized_manifest")" = "3072"
  test "$(jq -r '.config.includeOpenSSH' "$sized_manifest")" = "true"

  touch "$out"
''
