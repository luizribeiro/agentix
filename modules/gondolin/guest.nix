{ lib, config, pkgs, ... }:

let
  cfg = config.virtualisation.gondolin.guest;
  defaultArch =
    if pkgs.stdenv.hostPlatform.isAarch64 then
      "aarch64"
    else
      "x86_64";
in
{
  options.virtualisation.gondolin.guest = {
    enable = lib.mkEnableOption "Gondolin guest profile";

    arch = lib.mkOption {
      type = lib.types.enum [ "x86_64" "aarch64" ];
      default = defaultArch;
      description = "Target architecture for Gondolin guest assets.";
    };

    rootfsLabel = lib.mkOption {
      type = lib.types.str;
      default = "gondolin-root";
      description = "Root filesystem label for the Gondolin guest image.";
    };

    includeOpenSSH = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether OpenSSH compatibility should be enabled in the guest.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to include in the Gondolin guest environment.";
    };

    diskSizeMb = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Optional fixed rootfs size in MiB.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "virtualisation.gondolin.guest is currently supported on Linux only.";
      }
      {
        assertion =
          (cfg.arch == "x86_64" && pkgs.stdenv.hostPlatform.isx86_64)
          || (cfg.arch == "aarch64" && pkgs.stdenv.hostPlatform.isAarch64);
        message = "virtualisation.gondolin.guest.arch must match the current Linux host platform architecture.";
      }
      {
        assertion = cfg.rootfsLabel != "";
        message = "virtualisation.gondolin.guest.rootfsLabel must not be empty.";
      }
    ];

    environment.systemPackages = cfg.extraPackages;
  };
}
