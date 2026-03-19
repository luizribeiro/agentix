# agentix

> Your AI agents, packaged with Nix.

`agentix` is a single Nix flake that bundles popular AI coding CLIs so you can install, run, and pin them from one place.

Looking for Gondolin VM guest/assets tooling? See [gondolin-nix](https://github.com/luizribeiro/gondolin-nix).

## Available packages

| Package | Binary | Version | Description |
|---------|--------|---------|-------------|
| `codex-cli` | `codex` | 0.116.0 | OpenAI Codex CLI tool |
| `claude-code` | `claude` | 2.1.80 | Anthropic's official CLI for Claude |
| `gemini-cli` | `gemini` | 0.34.0 | Google's Gemini AI CLI |
| `crush` | `crush` | 0.22.1 | Charmbracelet's AI coding agent |
| `opencode` | `opencode` | 1.2.27 | Anomaly's AI coding agent |
| `pi` | `pi` | 0.60.0 | pi.dev minimal terminal-based coding agent |
| `default` | all | - | Combined package with all tools |

Package versions are continuously refreshed via the repository update workflow.

Inspired by [codex-cli-nix](https://github.com/sadjow/codex-cli-nix) and [claude-code-nix](https://github.com/sadjow/claude-code-nix).

## Quick start

Install everything:

```bash
nix profile install github:luizribeiro/agentix
```

Install one package:

```bash
nix profile install github:luizribeiro/agentix#codex-cli
```

Run one app without installing:

```bash
nix run github:luizribeiro/agentix#codex
nix run github:luizribeiro/agentix#pi
```

## Use in another flake (overlay)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    agentix.url = "github:luizribeiro/agentix";
  };

  outputs = { self, nixpkgs, agentix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ agentix.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          codex-cli
          claude-code
          gemini-cli
          crush
          opencode
          pi
        ];
      };
    };
}
```

## Development

```bash
# optional: auto-load dev shell in this repo
direnv allow

# enter development environment
nix develop

# run checks
nix flake check
```

## Updating packages

```bash
./scripts/update-package.nu codex-cli
./scripts/update-package.nu claude-code
./scripts/update-package.nu gemini-cli
./scripts/update-package.nu crush
./scripts/update-package.nu opencode
./scripts/update-package.nu pi
```

## Notes

- `codex-cli` and `claude-code` are unfree packages (`config.allowUnfree = true`).
- Automatic updates run in `.github/workflows/update.yml`.

## Contributing

PRs welcome. Please run `nix flake check` before submitting.