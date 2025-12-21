# agentix

> Your AI agents, packaged with Nix

**agentix** is a unified Nix flake for popular AI CLI tools:
- **codex-cli** - OpenAI Codex CLI
- **claude-code** - Anthropic's Claude Code CLI
- **gemini-cli** - Google's Gemini CLI
- **crush** - Charmbracelet's Crush AI coding agent

Inspired by [codex-cli-nix](https://github.com/sadjow/codex-cli-nix) and [claude-code-nix](https://github.com/sadjow/claude-code-nix).

## Features

- ✨ Four AI agents in one flake
- 🔄 Automatic hourly updates via GitHub Actions
- 📦 Individual or combined installation
- 🎯 Multi-platform support (Linux x86_64/ARM64, macOS ARM64)
- 🔒 Reproducible builds with locked dependencies

## Quick Start

### Install all tools

```bash
nix profile install github:luizribeiro/agentix
```

### Install individual tools

```bash
# Just codex
nix profile install github:luizribeiro/agentix#codex-cli

# Just claude
nix profile install github:luizribeiro/agentix#claude-code

# Just gemini
nix profile install github:luizribeiro/agentix#gemini-cli

# Just crush
nix profile install github:luizribeiro/agentix#crush
```

### Run without installing

```bash
# Run codex directly
nix run github:luizribeiro/agentix#codex

# Run claude directly
nix run github:luizribeiro/agentix#claude

# Run gemini directly
nix run github:luizribeiro/agentix#gemini

# Run crush directly
nix run github:luizribeiro/agentix#crush
```

## Usage in Other Flakes

### Using the overlay

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
        ];
      };
    };
}
```

### Using packages directly

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
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          agentix.packages.${system}.codex-cli
          agentix.packages.${system}.claude-code
          agentix.packages.${system}.gemini-cli
          agentix.packages.${system}.crush
        ];
      };
    };
}
```

## Available Packages

| Package | Binary | Version | License | Description |
|---------|--------|---------|---------|-------------|
| `codex-cli` | `codex` | 0.77.0 | Unfree | OpenAI Codex CLI tool |
| `claude-code` | `claude` | 2.0.75 | Unfree | Anthropic's official CLI for Claude |
| `gemini-cli` | `gemini` | 0.21.3 | Apache 2.0 | Google's Gemini AI CLI |
| `crush` | `crush` | 0.22.1 | MIT | Charmbracelet's AI coding agent |
| `default` | All | - | Mixed | Combined package with all four tools |

## Supported Platforms

- `aarch64-darwin` - macOS on Apple Silicon (M1/M2/M3)
- `aarch64-linux` - Linux on ARM64
- `x86_64-linux` - Linux on x86_64

## Using direnv

This repository includes a `.envrc` file for automatic development environment loading with [direnv](https://direnv.net/):

```bash
# Allow direnv to load the flake
direnv allow

# The development shell will now load automatically when you cd into the directory
# You'll have access to: nixpkgs-fmt, nix-prefetch-git, nodejs_22, jq
```

If you don't have direnv installed:
```bash
# NixOS
nix-env -iA nixpkgs.direnv

# With nix profile
nix profile install nixpkgs#direnv

# Then add to your shell rc (~/.bashrc, ~/.zshrc, etc.)
eval "$(direnv hook bash)"  # or zsh, fish, etc.
```

## Development

### Building locally

```bash
# Build individual packages
nix build .#codex-cli
nix build .#claude-code
nix build .#gemini-cli
nix build .#crush

# Build all tools
nix build .#default

# Check flake
nix flake check
```

### Development shell

```bash
nix develop
```

Includes:
- `nixpkgs-fmt` - Nix code formatter
- `nix-prefetch-git` - Git repository prefetcher
- `nodejs_22` - Node.js for testing
- `jq` - JSON processor
- `nushell` - Shell for running update scripts

### Updating packages

The workflow automatically updates packages hourly. To manually update a package, use the provided Nushell script:

```bash
# Update a specific package
./scripts/update-package.nu codex-cli
./scripts/update-package.nu claude-code
./scripts/update-package.nu gemini-cli
./scripts/update-package.nu crush
```

The script will:
1. Fetch the latest version from npm
2. Compare with the current version
3. If different, calculate new hashes and update the package file
4. Output whether the package was updated

**How it works:**
- For `codex-cli` and `claude-code` (FOD packages): Fetches tarball hash using `nix-prefetch-url`
- For `gemini-cli` (buildNpmPackage): Builds twice to extract source and npmDeps hashes from error output
- For `crush` (buildGoModule): Fetches from GitHub and extracts vendor hash from build output

See [scripts/update-package.nu](scripts/update-package.nu) for implementation details.

## Automatic Updates

This flake uses GitHub Actions to automatically check for updates every hour:

1. Runs `scripts/update-package.nu` for each package
2. The script fetches latest versions from npm and updates package files
3. Runs `nix flake check` to verify builds
4. Auto-commits and pushes changes if tests pass

The update logic is centralized in [scripts/update-package.nu](scripts/update-package.nu) and called by [.github/workflows/update.yml](.github/workflows/update.yml).

## Project Structure

```
.
├── flake.nix                    # Main flake definition
├── flake.lock                   # Locked dependencies
├── .envrc                       # direnv configuration
├── scripts/
│   └── update-package.nu        # Package update script (Nushell)
├── packages/
│   ├── codex-cli/
│   │   └── default.nix          # codex-cli package
│   ├── claude-code/
│   │   └── default.nix          # claude-code package
│   ├── gemini-cli/
│   │   └── default.nix          # gemini-cli package
│   └── crush/
│       └── default.nix          # crush package
├── .github/
│   └── workflows/
│       └── update.yml           # Auto-update workflow
└── README.md
```

## License Notes

- **codex-cli**: Unfree license (requires `config.allowUnfree = true`)
- **claude-code**: Unfree/Proprietary license (requires `config.allowUnfree = true`)
- **gemini-cli**: Apache 2.0 (free and open source)
- **crush**: MIT (free and open source)

When using this flake, make sure to set `config.allowUnfree = true` in your nixpkgs configuration if you want to use codex-cli or claude-code.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `nix flake check`
5. Submit a pull request

## Related Projects

- [codex-cli-nix](https://github.com/sadjow/codex-cli-nix) - Original codex-cli Nix package
- [claude-code-nix](https://github.com/sadjow/claude-code-nix) - Original claude-code Nix package
- [nixpkgs gemini-cli](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ge/gemini-cli/package.nix) - Official nixpkgs gemini-cli

## Acknowledgments

Special thanks to:
- [@sadjow](https://github.com/sadjow) for the original codex-cli-nix and claude-code-nix implementations
- The NixOS community for gemini-cli packaging
- OpenAI, Anthropic, and Google for their amazing AI tools