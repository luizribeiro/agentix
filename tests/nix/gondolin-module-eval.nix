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

  nixosNoSsh = lib.nixosSystem {
    inherit system;
    modules = [
      module
      {
        virtualisation.gondolin.guest = {
          enable = true;
          includeOpenSSH = false;
        };
      }
    ];
  };

  cfg = nixos.config.virtualisation.gondolin.guest;
  cfgNoSsh = nixosNoSsh.config.virtualisation.gondolin.guest;

  conflictingSshd = builtins.tryEval (
    (lib.nixosSystem {
      inherit system;
      modules = [
        module
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

  _ = assert cfg.enable;
    assert cfg.arch == hostDefaultArch;
    assert cfg.rootfsLabel == "gondolin-root";
    assert cfg.includeOpenSSH;
    assert cfg.extraPackages == [ ];
    assert cfg.diskSizeMb == null;

    assert cfgNoSsh.enable;
    assert !cfgNoSsh.includeOpenSSH;

    assert lib.elem pkgs.gondolin-guest-bins systemPackages;
    assert lib.elem pkgs.bashInteractive systemPackages;
    assert lib.elem pkgs.openssh systemPackages;
    assert lib.elem pkgs.gondolin-guest-bins systemPackagesNoSsh;
    assert lib.elem pkgs.bashInteractive systemPackagesNoSsh;
    assert !(lib.elem pkgs.openssh systemPackagesNoSsh);

    assert !conflictingSshd.success;

    assert lib.elem "L+ /bin/sh - - - - /run/current-system/sw/bin/sh" tmpfilesRules;
    assert lib.elem "L+ /bin/bash - - - - /run/current-system/sw/bin/bash" tmpfilesRules;
    assert lib.elem "L+ /usr/sbin/sshd - - - - /run/current-system/sw/bin/sshd" tmpfilesRules;
    assert !(lib.elem "L+ /usr/sbin/sshd - - - - /run/current-system/sw/bin/sshd" tmpfilesRulesNoSsh);

    assert sandboxService.wantedBy == [ "multi-user.target" ];
    assert sandboxService.serviceConfig.Restart == "on-failure";
    assert lib.hasInfix "gondolin-sandbox-stack" sandboxService.serviceConfig.ExecStart;
    true;
in
pkgs.runCommand "gondolin-module-eval" { } ''
  echo "gondolin guest module options evaluate correctly" > "$out"
''
