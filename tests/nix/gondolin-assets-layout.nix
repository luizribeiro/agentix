{ nixpkgs, system }:

let
  pkgs = import nixpkgs { inherit system; };
  lib = pkgs.lib;

  gondolinAssetsLib = import ../../lib/gondolin-assets.nix {
    inherit lib pkgs;
  };

  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";

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

  assets = gondolinAssetsLib.mkGondolinAssets {
    config = nixos.config;
    inherit arch;
  };
in
pkgs.runCommand "gondolin-assets-layout" { nativeBuildInputs = [ pkgs.jq ]; } ''
  set -euo pipefail

  test -f ${assets}/vmlinuz-virt
  test -f ${assets}/initramfs.cpio.lz4
  test -f ${assets}/rootfs.ext4
  test -f ${assets}/manifest.json

  test "$(jq -r '.assets.kernel' ${assets}/manifest.json)" = "vmlinuz-virt"
  test "$(jq -r '.assets.initramfs' ${assets}/manifest.json)" = "initramfs.cpio.lz4"
  test "$(jq -r '.assets.rootfs' ${assets}/manifest.json)" = "rootfs.ext4"

  touch "$out"
''
