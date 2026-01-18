{
  description = "agentix - Your AI agents, packaged with Nix (codex-cli, claude-code, gemini-cli, crush)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        codex-cli = final.callPackage ./packages/codex-cli { };
        claude-code = final.callPackage ./packages/claude-code { };
        gemini-cli = final.callPackage ./packages/gemini-cli { };
        crush = final.callPackage ./packages/crush { };
        opencode = final.callPackage ./packages/opencode { };
      };

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      overlays.default = overlay;
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

          default = pkgs.buildEnv {
            name = "agentix";
            paths = [
              pkgs.codex-cli
              pkgs.claude-code
              pkgs.gemini-cli
              pkgs.crush
              pkgs.opencode
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
            echo ""
            echo "Build packages:"
            echo "  nix build .#codex-cli"
            echo "  nix build .#claude-code"
            echo "  nix build .#gemini-cli"
            echo "  nix build .#crush"
            echo "  nix build .#opencode"
            echo "  nix build .#default  # agentix with all five tools"
          '';
        };
      });
}
