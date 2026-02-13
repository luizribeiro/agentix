{ lib
, nixosSystem
, overlay
, gondolinGuestModule
}:
let
  defaultGuestArchForSystem = system:
    if lib.hasPrefix "aarch64" system then
      "aarch64"
    else
      "x86_64";

  mkGondolinGuestSystem =
    { system
    , modules ? [ ]
    , specialArgs ? { }
    , arch ? defaultGuestArchForSystem system
    , rootfsLabel ? "gondolin-root"
    , includeOpenSSH ? true
    , diskSizeMb ? null
    , stateVersion ? "25.11"
    }:
    nixosSystem {
      inherit system specialArgs;
      modules = [
        gondolinGuestModule
        ({ ... }: {
          nixpkgs.overlays = [ overlay ];

          virtualisation.gondolin.guest = {
            enable = true;
            inherit arch rootfsLabel includeOpenSSH diskSizeMb;
          };

          fileSystems."/" = {
            device = "/dev/disk/by-label/${rootfsLabel}";
            fsType = "ext4";
          };

          boot.loader.grub.devices = [ "/dev/vda" ];
          system.stateVersion = stateVersion;
        })
      ] ++ modules;
    };

  mkGondolinAssets =
    { guestSystem ? null
    , system ? null
    , ...
    }@args:
    let
      resolvedGuestSystem =
        if guestSystem != null then
          guestSystem
        else if system != null then
          mkGondolinGuestSystem (builtins.removeAttrs args [ "guestSystem" ])
        else
          throw "mkGondolinAssets requires either guestSystem or system";
    in
    resolvedGuestSystem.config.system.build.gondolinAssets;

  mkGondolinWithAssets =
    { pkgs
    , assets
    , name ? "gondolin-with-assets"
    }:
    pkgs.writeShellScriptBin name ''
      export GONDOLIN_GUEST_DIR=${assets}
      exec ${pkgs.gondolin}/bin/gondolin "$@"
    '';
in
{
  inherit
    defaultGuestArchForSystem
    mkGondolinGuestSystem
    mkGondolinAssets
    mkGondolinWithAssets
    ;
}
