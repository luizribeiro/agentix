{
  description = "agentix - Your AI agents, packaged with Nix (codex-cli, claude-code, gemini-cli)";

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

          default = pkgs.buildEnv {
            name = "agentix";
            paths = [
              pkgs.codex-cli
              pkgs.claude-code
              pkgs.gemini-cli
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

          default = self.apps.${system}.claude;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            nix-prefetch-git
            nodejs_22
            jq
          ];

          shellHook = ''
            echo "agentix - Development Shell"
            echo "==========================="
            echo "Available commands:"
            echo "  - nixpkgs-fmt: Format Nix files"
            echo "  - nix-prefetch-git: Prefetch git repositories"
            echo ""
            echo "Build packages with:"
            echo "  nix build .#codex-cli"
            echo "  nix build .#claude-code"
            echo "  nix build .#gemini-cli"
            echo "  nix build .#default  # agentix with all three tools"
          '';
        };
      });
}
