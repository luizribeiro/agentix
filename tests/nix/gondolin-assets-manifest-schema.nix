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
pkgs.runCommand "gondolin-assets-manifest-schema" { nativeBuildInputs = [ pkgs.coreutils pkgs.jq ]; } ''
  set -euo pipefail

  jq -e '
    has("assets") and
    has("checksums") and
    has("config") and
    (.config | has("arch") and (.arch | type == "string")) and
    (.assets | has("kernel") and has("initramfs") and has("rootfs")) and
    (.checksums | has("kernel") and has("initramfs") and has("rootfs")) and
    ([.checksums.kernel, .checksums.initramfs, .checksums.rootfs] | all(test("^[a-f0-9]{64}$")))
  ' ${assets}/manifest.json > /dev/null

  test "$(jq -r '.config.arch' ${assets}/manifest.json)" = "${arch}"
  test "$(jq -r '.checksums.kernel' ${assets}/manifest.json)" = "$(${pkgs.coreutils}/bin/sha256sum ${assets}/vmlinuz-virt | ${pkgs.coreutils}/bin/cut -d ' ' -f1)"
  test "$(jq -r '.checksums.initramfs' ${assets}/manifest.json)" = "$(${pkgs.coreutils}/bin/sha256sum ${assets}/initramfs.cpio.lz4 | ${pkgs.coreutils}/bin/cut -d ' ' -f1)"
  test "$(jq -r '.checksums.rootfs' ${assets}/manifest.json)" = "$(${pkgs.coreutils}/bin/sha256sum ${assets}/rootfs.ext4 | ${pkgs.coreutils}/bin/cut -d ' ' -f1)"

  touch "$out"
''
