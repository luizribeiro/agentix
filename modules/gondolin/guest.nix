{ lib, config, pkgs, ... }:

let
  cfg = config.virtualisation.gondolin.guest;
  gondolinAssetsLib = import ../../lib/gondolin-assets.nix {
    inherit lib pkgs;
  };

  defaultArch =
    if pkgs.stdenv.hostPlatform.isAarch64 then
      "aarch64"
    else
      "x86_64";

  waitTimeoutSeconds = 30;
  waitSleepSeconds = 1;

  gondolinSandboxStackScript = pkgs.writeShellScript "gondolin-sandbox-stack" ''
    set -eu

    timeout_seconds=${toString waitTimeoutSeconds}
    sleep_seconds=${toString waitSleepSeconds}
    max_attempts=$((timeout_seconds / sleep_seconds))

    log() {
      echo "[gondolin-sandbox-stack] $*"
    }

    wait_for_virtio_node() {
      node_path="$1"
      node_name="$2"
      attempt=1

      while [ "$attempt" -le "$max_attempts" ]; do
        if [ -e "$node_path" ]; then
          log "Ready: $node_name ($node_path)"
          return 0
        fi

        log "Waiting for $node_name ($node_path), attempt $attempt/$max_attempts"
        sleep "$sleep_seconds"
        attempt=$((attempt + 1))
      done

      log "ERROR: timed out after ${toString waitTimeoutSeconds}s waiting for $node_name ($node_path)"
      return 1
    }

    sandboxfs_mount="/data"
    sandboxfs_binds=""

    if [ -r /proc/cmdline ]; then
      for arg in $(cat /proc/cmdline); do
        case "$arg" in
          sandboxfs.mount=*)
            sandboxfs_mount="''${arg#sandboxfs.mount=}"
            ;;
          sandboxfs.bind=*)
            sandboxfs_binds="''${arg#sandboxfs.bind=}"
            ;;
        esac
      done
    fi

    wait_for_sandboxfs_mount() {
      attempt=1
      while [ "$attempt" -le "$max_attempts" ]; do
        if grep -q " $sandboxfs_mount fuse.sandboxfs " /proc/mounts; then
          log "sandboxfs mounted at $sandboxfs_mount"
          return 0
        fi
        sleep "$sleep_seconds"
        attempt=$((attempt + 1))
      done

      log "ERROR: timed out waiting for sandboxfs mount at $sandboxfs_mount"
      return 1
    }

    log "Starting Gondolin sandbox stack"

    wait_for_virtio_node /dev/virtio-ports/virtio-port control-channel
    wait_for_virtio_node /dev/virtio-ports/virtio-fs filesystem-channel
    ${lib.optionalString cfg.includeOpenSSH "wait_for_virtio_node /dev/virtio-ports/virtio-ssh ssh-channel"}

    if grep -q " $sandboxfs_mount " /proc/mounts; then
      log "Unmounting pre-existing mount at $sandboxfs_mount"
      ${pkgs.util-linux}/bin/umount -l "$sandboxfs_mount" || true
    fi

    if ! mkdir -p "$sandboxfs_mount"; then
      log "WARNING: failed to prepare $sandboxfs_mount; attempting lazy unmount + retry"
      ${pkgs.util-linux}/bin/umount -l "$sandboxfs_mount" || true
      mkdir -p "$sandboxfs_mount"
    fi

    log "Launching sandboxfs at $sandboxfs_mount"
    ${pkgs.gondolin-guest-bins}/bin/sandboxfs --mount "$sandboxfs_mount" --rpc-path /dev/virtio-ports/virtio-fs &
    log "sandboxfs started (pid $!)"

    sandboxfs_ready=0
    if wait_for_sandboxfs_mount; then
      sandboxfs_ready=1
    else
      sandboxfs_ready=0
      log "WARNING: sandboxfs mount not ready; continuing to launch sandboxd"
    fi

    if [ "$sandboxfs_ready" -eq 1 ] && [ -n "$sandboxfs_binds" ]; then
      old_ifs="$IFS"
      IFS=','
      for bind in $sandboxfs_binds; do
        [ -n "$bind" ] || continue
        mkdir -p "$bind"

        if [ "$sandboxfs_mount" = "/" ]; then
          bind_source="$bind"
        else
          bind_source="$sandboxfs_mount$bind"
        fi

        log "binding sandboxfs $bind_source -> $bind"
        ${pkgs.util-linux}/bin/mount --bind "$bind_source" "$bind"
      done
      IFS="$old_ifs"
    fi

    ${lib.optionalString cfg.includeOpenSSH ''
      log "Launching sandboxssh"
      ${pkgs.gondolin-guest-bins}/bin/sandboxssh &
      log "sandboxssh started (pid $!)"
    ''}

    log "Launching sandboxd in foreground"
    exec ${pkgs.gondolin-guest-bins}/bin/sandboxd
  '';
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
    system.build.gondolinAssets = gondolinAssetsLib.mkGondolinAssets {
      inherit config;
      arch = cfg.arch;
      rootfsLabel = cfg.rootfsLabel;
      diskSizeMb = cfg.diskSizeMb;
      includeOpenSSH = cfg.includeOpenSSH;
    };

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
      {
        assertion = !(cfg.includeOpenSSH && config.services.openssh.enable);
        message =
          "virtualisation.gondolin.guest.includeOpenSSH provides sshd compatibility only. "
          + "Do not enable services.openssh with Gondolin guest mode; let Gondolin manage sshd via vm.enableSsh().";
      }
    ];

    environment.systemPackages =
      [
        pkgs.gondolin-guest-bins
        pkgs.bashInteractive
      ]
      ++ lib.optionals cfg.includeOpenSSH [ pkgs.openssh ]
      ++ cfg.extraPackages;

    environment.etc = lib.mkIf cfg.includeOpenSSH {
      "ssh/sshd_config".text = "";
    };

    users.groups = lib.mkIf cfg.includeOpenSSH {
      sshd = { };
    };

    users.users = lib.mkIf cfg.includeOpenSSH {
      sshd = {
        isSystemUser = true;
        group = "sshd";
        home = "/var/empty";
        description = "sshd privilege separation user";
      };
    };

    systemd.tmpfiles.rules =
      [
        "L+ /bin/sh - - - - /run/current-system/sw/bin/sh"
        "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
        "L+ /bin/true - - - - /run/current-system/sw/bin/true"
      ]
      ++ lib.optionals cfg.includeOpenSSH [
        "d /usr/sbin 0755 root root -"
        "L+ /usr/sbin/sshd - - - - /run/current-system/sw/bin/sshd"
      ];

    systemd.services.gondolin-sandbox-stack = {
      description = "Gondolin guest daemon compatibility stack";
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "systemd-udevd.service"
        "systemd-modules-load.service"
      ];
      wants = [
        "systemd-udevd.service"
        "systemd-modules-load.service"
      ];

      unitConfig = {
        StartLimitIntervalSec = 120;
        StartLimitBurst = 10;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = gondolinSandboxStackScript;
        Restart = "on-failure";
        RestartSec = "2s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
