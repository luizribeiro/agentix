{
  description = "agentix - Your AI agents, packaged with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      lib = nixpkgs.lib;

      agentixLib = import ./lib {
        inherit lib;
        nixosSystem = lib.nixosSystem;
      };

      inherit (agentixLib)
        overlay
        ;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # Discover every subdirectory of packages/ that has a default.nix.
      # Same enumeration the overlay uses.
      packageNames = lib.attrNames (
        lib.filterAttrs
          (name: type: type == "directory"
            && builtins.pathExists (./packages + "/${name}/default.nix"))
          (builtins.readDir ./packages)
      );
    in
    {
      # Expose pre-built packages so consumers aren't forced to rebuild
      # with their own nixpkgs, which may lack features like
      # npmDepsFetcherVersion = 2.
      overlays.default = final: prev:
        let system = prev.stdenv.hostPlatform.system;
        in if self.packages ? ${system}
          then builtins.removeAttrs self.packages.${system} [ "default" ]
          else { };

      lib = { };

      nixosModules = { };

      nixosConfigurations = { };
    } //
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };

        discoveredPackages = lib.genAttrs packageNames (name: pkgs.${name});

        # Each app's binary name comes from meta.mainProgram on the package.
        # `nix run .#<bin>` matches the actual CLI name.
        appsByBin = lib.mapAttrs'
          (name: pkg: lib.nameValuePair pkg.meta.mainProgram {
            type = "app";
            program = "${pkg}/bin/${pkg.meta.mainProgram}";
          })
          discoveredPackages;
      in
      {
        packages = discoveredPackages // {
          default = pkgs.buildEnv {
            name = "agentix";
            paths = lib.attrValues discoveredPackages;
            meta = {
              description = "agentix - Your AI agents, packaged with Nix";
              platforms = supportedSystems;
            };
          };
        };

        apps = appsByBin // {
          default = self.apps.${system}.claude;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            nix-prefetch-git
            nodejs_22
            jq
            nushell
          ];

          shellHook = ''
            echo "agentix - Development Shell"
            echo "==========================="
            echo "Available commands:"
            echo "  - nixpkgs-fmt: Format Nix files"
            echo "  - nix-prefetch-git: Prefetch git repositories"
            echo "  - nu: Nushell for running update scripts"
            echo ""
            echo "Packages (${toString (lib.length packageNames)}):"
            ${lib.concatMapStringsSep "\n            " (n: ''echo "  - ${n}"'') packageNames}
            echo ""
            echo "Update packages:     ./scripts/update-package.nu [--all] <name>..."
            echo "Build a package:     nix build .#<name>"
            echo "Build all packages:  nix build .#default"
          '';
        };
      });
}
