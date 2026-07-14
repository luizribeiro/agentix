# agentix

> Your AI agents, packaged with Nix.

`agentix` is a single Nix flake that bundles popular AI coding CLIs so you can install, run, and pin them from one place.

Looking for Gondolin VM guest/assets tooling? See [gondolin-nix](https://github.com/luizribeiro/gondolin-nix).

## Available packages

<!-- BEGIN package-table -->

| Package | Binary | Version | Description |
|---------|--------|---------|-------------|
| `antigravity-cli` | `agy` | 1.1.2 | Google's Antigravity CLI - terminal-based AI coding agent |
| `claude-code` | `claude` | 2.1.208 | Claude Code CLI - Anthropic's official CLI for Claude |
| `codex-cli` | `codex` | 0.144.3 | OpenAI Codex CLI tool |
| `crush` | `crush` | 0.75.0 | The glamourous AI coding agent for your favourite terminal |
| `gemini-cli` | `gemini` | 0.50.0 | AI agent that brings the power of Gemini directly into your terminal |
| `opencode` | `opencode` | 1.17.20 | AI coding agent built for the terminal |
| `pi` | `pi` | 0.73.1 | pi.dev - A minimal terminal-based coding agent |
| `roborev` | `roborev` | 0.56.0 | Continuous code review daemon for AI coding agents |
| `default` | all | - | Combined package with all tools |
<!-- END package-table -->

The table above is regenerated from each package's `default.nix` by
`./scripts/render-readme.nu`. Versions are continuously refreshed via
the auto-update workflow.

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
nix run github:luizribeiro/agentix#roborev
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
          antigravity-cli
          crush
          opencode
          pi
          roborev
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
# every discovered package
./scripts/update-package.nu --all

# one or more by name
./scripts/update-package.nu codex-cli
./scripts/update-package.nu codex-cli claude-code
```

## Notes

- `codex-cli`, `claude-code`, and `antigravity-cli` are unfree packages (`config.allowUnfree = true`).
- Automatic updates run in `.github/workflows/update.yml`.

## Contributing

PRs welcome. Please run `nix flake check` before submitting.