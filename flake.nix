{
  description = "agentix - Your AI agents, packaged with Nix (codex-cli, claude-code, gemini-cli, crush, opencode, pi)";

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
        ;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
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

      in
      {
        packages = {
          codex-cli = pkgs.codex-cli;
          claude-code = pkgs.claude-code;
          gemini-cli = pkgs.gemini-cli;
          crush = pkgs.crush;
          opencode = pkgs.opencode;
          pi = pkgs.pi;

          default = pkgs.buildEnv {
            name = "agentix";
            paths = [
              pkgs.codex-cli
              pkgs.claude-code
              pkgs.gemini-cli
              pkgs.crush
              pkgs.opencode
              pkgs.pi
            ];
            meta = {
              description = "agentix - Your AI agents, packaged with Nix";
              platforms = supportedSystems;
            };
          };
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
            echo "Update packages:"
            echo "  ./scripts/update-package.nu codex-cli"
            echo "  ./scripts/update-package.nu claude-code"
            echo "  ./scripts/update-package.nu gemini-cli"
            echo "  ./scripts/update-package.nu crush"
            echo "  ./scripts/update-package.nu opencode"
            echo "  ./scripts/update-package.nu pi"
            echo ""
            echo "Build packages:"
            echo "  nix build .#codex-cli"
            echo "  nix build .#claude-code"
            echo "  nix build .#gemini-cli"
            echo "  nix build .#crush"
            echo "  nix build .#opencode"
            echo "  nix build .#pi"
            echo "  nix build .#default  # agentix with all six tools"
          '';
        };
      });
}
