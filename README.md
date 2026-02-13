# agentix

> Your AI agents, packaged with Nix.

`agentix` is a single Nix flake that bundles multiple tools commonly used by AI agents
(coding CLIs and a local VM sandbox), so you can install, run, and pin them from one place.

## Available packages

| Package | Binary | Version | Description |
|---------|--------|---------|-------------|
| `codex-cli` | `codex` | 0.101.0 | OpenAI Codex CLI tool |
| `claude-code` | `claude` | 2.1.42 | Anthropic's official CLI for Claude |
| `gemini-cli` | `gemini` | 0.28.2 | Google's Gemini AI CLI |
| `crush` | `crush` | 0.22.1 | Charmbracelet's AI coding agent |
| `opencode` | `opencode` | 1.1.65 | Anomaly's AI coding agent |
| `pi` | `pi` | 0.52.11 | pi.dev minimal terminal-based coding agent |
| `gondolin` | `gondolin` | 0.2.1 | Local Linux micro-VM sandbox for AI agents |
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
nix run github:luizribeiro/agentix#gondolin
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
          gondolin
        ];
      };
    };
}
```

## Gondolin guest helpers (module + flake lib)

Agentix exports both:
- `nixosModules.gondolin-guest`
- flake `lib` helpers to make guest systems/assets easy to compose:
  - `agentix.lib.defaultGuestArchForSystem`
  - `agentix.lib.mkGondolinGuestSystem`
  - `agentix.lib.mkGondolinAssets`
  - `agentix.lib.mkGondolinWithAssets`

### Minimal module usage

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    agentix.url = "github:luizribeiro/agentix";
  };

  outputs = { self, nixpkgs, agentix, ... }: {
    nixosConfigurations.gondolin-guest = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        agentix.nixosModules.gondolin-guest
        ({ ... }: {
          virtualisation.gondolin.guest.enable = true;

          fileSystems."/" = {
            device = "/dev/disk/by-label/gondolin-root";
            fsType = "ext4";
          };

          boot.loader.grub.devices = [ "/dev/vda" ];
          system.stateVersion = "25.11";
        })
      ];
    };
  };
}
```

Build assets from that `nixosConfiguration`:

```bash
nix build .#nixosConfigurations.gondolin-guest.config.system.build.gondolinAssets
```

Run Gondolin with those assets:

```bash
GONDOLIN_GUEST_DIR="$(readlink -f result)" nix run .#gondolin -- exec -- echo hello
```

### Recommended: helper-based usage in downstream flakes

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    agentix.url = "github:luizribeiro/agentix";
  };

  outputs = { self, nixpkgs, agentix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ agentix.overlays.default ];
      };

      guest = agentix.lib.mkGondolinGuestSystem {
        inherit system;
        modules = [
          ({ ... }: {
            # your guest customizations
            environment.systemPackages = [ pkgs.hello ];
          })
        ];
      };

      assets = agentix.lib.mkGondolinAssets {
        guestSystem = guest;
      };

      gondolinWithAssets = agentix.lib.mkGondolinWithAssets {
        inherit pkgs assets;
        name = "gondolin-project";
      };
    in
    {
      packages.${system}.gondolin-assets = assets;
      packages.${system}.gondolin = gondolinWithAssets;
    };
}
```

Build assets:

```bash
nix build .#gondolin-assets
```

Run Gondolin without manually setting `GONDOLIN_GUEST_DIR`:

```bash
nix run .#gondolin -- exec -- echo hello
```

Notes:
- `virtualisation.gondolin.guest.includeOpenSSH = true` supports `vm.enableSsh()`.
- Do not enable `services.openssh`; Gondolin manages sshd lifecycle itself.
- `sandboxingress` is not included yet.

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
./scripts/update-package.nu gondolin

# verify gondolin + gondolin-guest-bins lockstep
./scripts/update-package.nu --check-lockstep
```

When updating `gondolin`, the script also synchronizes `packages/gondolin-guest-bins/default.nix`.

## Notes

- `codex-cli` and `claude-code` are unfree packages (`config.allowUnfree = true`).
- Automatic updates run in `.github/workflows/update.yml`.

## Contributing

PRs welcome. Please run `nix flake check` before submitting.