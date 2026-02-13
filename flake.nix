{
  description = "agentix - Your AI agents, packaged with Nix (codex-cli, claude-code, gemini-cli, crush, opencode, pi, gondolin)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      agentixLib = import ./lib {
        lib = nixpkgs.lib;
        nixosSystem = nixpkgs.lib.nixosSystem;
      };

      inherit (agentixLib)
        overlay
        gondolinGuestModule
        gondolinHelpers
        ;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      inherit (gondolinHelpers)
        defaultGuestArchForSystem
        mkGondolinGuestSystem
        mkGondolinAssets
        mkGondolinWithAssets
        ;

      mkGondolinGuestTest = system: mkGondolinGuestSystem {
        inherit system;
        arch = defaultGuestArchForSystem system;
      };
    in
    {
      overlays.default = overlay;

      lib = {
        inherit
          defaultGuestArchForSystem
          mkGondolinGuestSystem
          mkGondolinAssets
          mkGondolinWithAssets
          ;
      };

      nixosModules = {
        gondolin-guest = gondolinGuestModule;
      };

      nixosConfigurations = {
        gondolin-guest-test-x86_64-linux = mkGondolinGuestTest "x86_64-linux";
        gondolin-guest-test-aarch64-linux = mkGondolinGuestTest "aarch64-linux";

      };
    } //
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };

      in
      {
        packages = {
          codex-cli = pkgs.codex-cli;
          claude-code = pkgs.claude-code;
          gemini-cli = pkgs.gemini-cli;
          crush = pkgs.crush;
          opencode = pkgs.opencode;
          pi = pkgs.pi;
          gondolin = pkgs.gondolin;

          default = pkgs.buildEnv {
            name = "agentix";
            paths = [
              pkgs.codex-cli
              pkgs.claude-code
              pkgs.gemini-cli
              pkgs.crush
              pkgs.opencode
              pkgs.pi
              pkgs.gondolin
            ];
            meta = {
              description = "agentix - Your AI agents, packaged with Nix";
              platforms = supportedSystems;
            };
          };
        } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          gondolin-guest-bins = pkgs.gondolin-guest-bins;
        };

        apps = {
          codex = {
            type = "app";
            program = "${pkgs.codex-cli}/bin/codex";
          };

          claude = {
            type = "app";
            program = "${pkgs.claude-code}/bin/claude";
          };

          gemini = {
            type = "app";
            program = "${pkgs.gemini-cli}/bin/gemini";
          };

          crush = {
            type = "app";
            program = "${pkgs.crush}/bin/crush";
          };

          opencode = {
            type = "app";
            program = "${pkgs.opencode}/bin/opencode";
          };

          pi = {
            type = "app";
            program = "${pkgs.pi}/bin/pi";
          };

          gondolin = {
            type = "app";
            program = "${pkgs.gondolin}/bin/gondolin";
          };

          default = self.apps.${system}.claude;
        };

        checks = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          gondolin-module-eval = import ./tests/nix/gondolin-module-eval.nix {
            inherit nixpkgs system;
            module = self.nixosModules.gondolin-guest;
          };

          gondolin-assets-layout = import ./tests/nix/gondolin-assets-layout.nix {
            inherit nixpkgs system;
          };

          gondolin-assets-manifest-schema = import ./tests/nix/gondolin-assets-manifest-schema.nix {
            inherit nixpkgs system;
          };

          gondolin-initramfs-content = import ./tests/nix/gondolin-initramfs-content.nix {
            inherit nixpkgs system;
          };

          gondolin-runtime-smoke =
            let
              assets = self.nixosConfigurations.gondolin-guest-test-x86_64-linux.config.system.build.gondolinAssets;
            in
            pkgs.runCommand "gondolin-runtime-smoke"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                  pkgs.nodejs_22
                  pkgs.qemu
                  pkgs.openssh
                  pkgs.gondolin
                ];
              }
              ''
                export HOME="$TMPDIR"
                export GONDOLIN_GUEST_DIR="${assets}"
                export GONDOLIN_SMOKE_TIMEOUT=45
                export NODE_PATH="${pkgs.gondolin}/lib/node_modules"

                ${pkgs.bash}/bin/bash ${./tests/runtime/gondolin-smoke.sh}
                ${pkgs.nodejs_22}/bin/node ${./tests/runtime/gondolin-ssh-smoke.js}

                touch "$out"
              '';
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
            echo "Update packages:"
            echo "  ./scripts/update-package.nu codex-cli"
            echo "  ./scripts/update-package.nu claude-code"
            echo "  ./scripts/update-package.nu gemini-cli"
            echo "  ./scripts/update-package.nu crush"
            echo "  ./scripts/update-package.nu opencode"
            echo "  ./scripts/update-package.nu pi"
            echo "  ./scripts/update-package.nu gondolin"
            echo ""
            echo "Build packages:"
            echo "  nix build .#codex-cli"
            echo "  nix build .#claude-code"
            echo "  nix build .#gemini-cli"
            echo "  nix build .#crush"
            echo "  nix build .#opencode"
            echo "  nix build .#pi"
            echo "  nix build .#gondolin"
            echo "  nix build .#default  # agentix with all seven tools"
          '';
        };
      });
}
