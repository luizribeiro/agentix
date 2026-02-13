{ lib, pkgs }:

let
  makeDiskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix";

  busyboxPackage =
    if pkgs.stdenv.hostPlatform.isLinux then
      assert pkgs.pkgsStatic ? busybox;
      pkgs.pkgsStatic.busybox
    else
      pkgs.busybox;

  kmodPackage =
    if pkgs.stdenv.hostPlatform.isLinux then
      assert pkgs.pkgsStatic ? kmod;
      pkgs.pkgsStatic.kmod
    else
      pkgs.kmod;

  mkGondolinInitramfs =
    { modulesTree ? null }:
    pkgs.runCommand "gondolin-initramfs"
      {
        nativeBuildInputs = [
          pkgs.cpio
          pkgs.findutils
          pkgs.lz4
        ];
      } ''
      set -euo pipefail

      root="$TMPDIR/initramfs-root"
      mkdir -p "$root"/{bin,sbin,proc,sys,dev,run,newroot}

      cp ${busyboxPackage}/bin/busybox "$root/bin/busybox"
      chmod 0755 "$root/bin/busybox"

      ${lib.optionalString (modulesTree != null) ''
        if [ -d "${modulesTree}/lib/modules" ]; then
          mkdir -p "$root/lib"
          cp -a "${modulesTree}/lib/modules" "$root/lib/modules"
        fi
      ''}

      for cmd in \
        sh mount umount mkdir sleep dmesg switch_root \
        cat echo ls test readlink; do
        ln -s busybox "$root/bin/$cmd"
      done

      cp ${kmodPackage}/bin/modprobe "$root/bin/modprobe"
      chmod 0755 "$root/bin/modprobe"

      cat > "$root/init" <<'EOF'
      #!/bin/sh
      set -eu

      export PATH=/bin:/sbin

      log() {
        echo "[gondolin-initramfs] $*"
      }

      failure_shell() {
        reason="$1"
        log "ERROR: $reason"
        log "Boot failed; dropping to emergency shell"
        exec sh
      }

      mkdir -p /proc /sys /dev /run /newroot

      mount -t proc proc /proc || failure_shell "failed to mount /proc"
      mount -t sysfs sysfs /sys || failure_shell "failed to mount /sys"
      mount -t devtmpfs devtmpfs /dev || failure_shell "failed to mount /dev"
      mount -t tmpfs tmpfs /run || failure_shell "failed to mount /run"

      modprobe virtio_mmio 2>/dev/null || log "modprobe virtio_mmio failed or not needed"
      modprobe virtio_blk 2>/dev/null || log "modprobe virtio_blk failed or not needed"
      modprobe ext4 2>/dev/null || log "modprobe ext4 failed or not needed"

      wait_limit=30
      wait_count=0
      while [ ! -b /dev/vda ] && [ "$wait_count" -lt "$wait_limit" ]; do
        log "waiting for /dev/vda ($wait_count/$wait_limit)"
        sleep 1
        wait_count=$((wait_count + 1))
      done

      [ -b /dev/vda ] || failure_shell "timed out waiting for /dev/vda"

      mount -t ext4 /dev/vda /newroot || failure_shell "failed to mount /dev/vda on /newroot"

      mkdir -p /newroot/proc /newroot/sys /newroot/dev /newroot/run

      if [ -x /newroot/sbin/init ]; then
        log "switch_root -> /sbin/init"
        exec switch_root /newroot /sbin/init
      fi

      if [ -x /newroot/init ]; then
        log "switch_root -> /init"
        exec switch_root /newroot /init
      fi

      if [ -L /newroot/nix/var/nix/profiles/system-1-link ]; then
        system_link_target=$(readlink /newroot/nix/var/nix/profiles/system-1-link || true)
        if [ -n "$system_link_target" ] && [ -x "/newroot$system_link_target/init" ]; then
          rel_init="$system_link_target/init"
          log "switch_root -> $rel_init"
          exec switch_root /newroot "$rel_init"
        fi
      fi

      failure_shell "no init found at /sbin/init, /init, or system-1-link target init"
      EOF

      chmod 0755 "$root/init"

      mkdir -p "$out"

      (
        cd "$root"
        find . -mindepth 1 -print | sort | cpio --quiet -o -H newc
      ) | lz4 -l -9 > "$out/initramfs.cpio.lz4"
    '';
in
{
  inherit mkGondolinInitramfs;

  mkGondolinAssets =
    { config
    , arch
    , rootfsLabel ? "gondolin-root"
    , diskSizeMb ? null
    , includeOpenSSH ? null
    ,
    }:
    let
      rootfsImage = makeDiskImage {
        inherit pkgs lib config;

        name = "gondolin-rootfs";
        format = "raw";
        baseName = "rootfs";
        partitionTableType = "none";
        label = rootfsLabel;
        installBootLoader = false;
        copyChannel = false;
        diskSize = if diskSizeMb == null then "auto" else toString diskSizeMb;
      };

      kernelPath = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
      initramfsPath = "${mkGondolinInitramfs { modulesTree = config.system.modulesTree; }}/initramfs.cpio.lz4";
      manifestConfigJson = builtins.toJSON (
        {
          inherit arch rootfsLabel;
        }
        // lib.optionalAttrs (diskSizeMb != null) { inherit diskSizeMb; }
        // lib.optionalAttrs (includeOpenSSH != null) { inherit includeOpenSSH; }
      );
    in
    pkgs.runCommand "gondolin-assets" { } ''
      set -euo pipefail

      checksum_file() {
        local file="$1"
        ${pkgs.coreutils}/bin/sha256sum "$file" | ${pkgs.coreutils}/bin/cut -d ' ' -f1
      }

      mkdir -p "$out"

      cp "${kernelPath}" "$out/vmlinuz-virt"
      cp "${initramfsPath}" "$out/initramfs.cpio.lz4"
      cp "${rootfsImage}/rootfs.img" "$out/rootfs.ext4"

      kernel_checksum="$(checksum_file "$out/vmlinuz-virt")"
      initramfs_checksum="$(checksum_file "$out/initramfs.cpio.lz4")"
      rootfs_checksum="$(checksum_file "$out/rootfs.ext4")"

      ${pkgs.jq}/bin/jq -n \
        --arg kernel "vmlinuz-virt" \
        --arg initramfs "initramfs.cpio.lz4" \
        --arg rootfs "rootfs.ext4" \
        --arg kernelChecksum "$kernel_checksum" \
        --arg initramfsChecksum "$initramfs_checksum" \
        --arg rootfsChecksum "$rootfs_checksum" \
        --argjson config '${manifestConfigJson}' \
        '{
          assets: {
            kernel: $kernel,
            initramfs: $initramfs,
            rootfs: $rootfs
          },
          checksums: {
            kernel: $kernelChecksum,
            initramfs: $initramfsChecksum,
            rootfs: $rootfsChecksum
          },
          config: $config
        }' > "$out/manifest.json"
    '';
}

