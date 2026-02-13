{ nixpkgs, system }:

let
  pkgs = import nixpkgs { inherit system; };
  lib = pkgs.lib;

  gondolinAssetsLib = import ../../lib/gondolin-assets.nix {
    inherit lib pkgs;
  };

  nixos = import "${nixpkgs}/nixos/lib/eval-config.nix" {
    inherit system;
    modules = [
      ({ ... }: {
        fileSystems."/" = {
          device = "/dev/disk/by-label/gondolin-root";
          fsType = "ext4";
        };

        boot.loader.grub.devices = [ "/dev/vda" ];
        system.stateVersion = "25.11";
      })
    ];
  };

  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";

  assets = gondolinAssetsLib.mkGondolinAssets {
    config = nixos.config;
    inherit arch;
  };
in
pkgs.runCommand "gondolin-initramfs-content"
{
  nativeBuildInputs = [ pkgs.cpio pkgs.gnugrep pkgs.lz4 ];
} ''
  set -euo pipefail

  unpack_dir="$TMPDIR/initramfs"
  mkdir -p "$unpack_dir"

  (
    cd "$unpack_dir"
    lz4 -dc ${assets}/initramfs.cpio.lz4 | cpio -id --quiet
  )

  test -x "$unpack_dir/init"
  test -x "$unpack_dir/bin/busybox"
  test -L "$unpack_dir/bin/sh"
  test -L "$unpack_dir/bin/switch_root"

  "$unpack_dir/bin/busybox" --help > /dev/null

  grep -q '/dev/vda' "$unpack_dir/init"
  grep -q 'switch_root' "$unpack_dir/init"
  grep -q 'modprobe virtio_blk' "$unpack_dir/init"
  grep -q 'modprobe ext4' "$unpack_dir/init"

  touch "$out"
''
