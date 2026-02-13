{ lib, pkgs }:

let
  makeDiskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix";
in
{
  mkGondolinAssets =
    { config
    , arch
    , rootfsLabel ? "gondolin-root"
    , diskSizeMb ? null
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
      initramfsPath = config.system.build.initialRamdisk;
    in
    pkgs.runCommand "gondolin-assets" { } ''
      set -euo pipefail

      checksum_file() {
        local file="$1"
        ${pkgs.coreutils}/bin/sha256sum "$file" | ${pkgs.coreutils}/bin/cut -d ' ' -f1
      }

      mkdir -p "$out"

      cp "${kernelPath}" "$out/vmlinuz-virt"

      initramfs_source="${initramfsPath}"
      if [ -d "$initramfs_source" ]; then
        initramfs_source="$(${pkgs.findutils}/bin/find "$initramfs_source" -maxdepth 1 -type f | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/head -n1)"
      fi
      cp "$initramfs_source" "$out/initramfs.cpio.lz4"

      cp "${rootfsImage}/rootfs.img" "$out/rootfs.ext4"

      kernel_checksum="$(checksum_file "$out/vmlinuz-virt")"
      initramfs_checksum="$(checksum_file "$out/initramfs.cpio.lz4")"
      rootfs_checksum="$(checksum_file "$out/rootfs.ext4")"

      cat > "$out/manifest.json" <<EOF
      {
        "assets": {
          "kernel": "vmlinuz-virt",
          "initramfs": "initramfs.cpio.lz4",
          "rootfs": "rootfs.ext4"
        },
        "checksums": {
          "kernel": "''${kernel_checksum}",
          "initramfs": "''${initramfs_checksum}",
          "rootfs": "''${rootfs_checksum}"
        },
        "config": {
          "arch": "${arch}"
        }
      }
      EOF
    '';
}
