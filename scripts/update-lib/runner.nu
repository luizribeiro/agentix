# Generic runner for declarative `packages/<name>/update.toml` configs.
#
# Each TOML carries enough information to drive a shared strategy (FOD or
# multihash) against either an npm or GitHub source. Packages whose
# distribution doesn't fit either strategy keep using `update.nu` and the
# dispatcher reaches for that path instead.
#
# Expected TOML shape:
#
#     [source]
#     type = "npm"              # or "github"
#     name = "@scope/name"      # npm only
#     # owner = "..."           # github only
#     # repo  = "..."           # github only
#
#     [strategy]
#     type = "fod"              # or "multihash"
#     # For fod:
#     platform_suffixes = ["darwin-arm64", "linux-x64", "linux-arm64"]
#     platform_layout   = "suffix"  # or "subpackage" (default: "suffix")
#     # For multihash:
#     hash_steps = [
#       { field = "hash",       label = "source hash" },
#       { field = "vendorHash", label = "vendorHash"  },
#     ]

use registry.nu *
use strategies.nu *

def read-config [toml_path: string]: nothing -> record {
    open $toml_path
}

def nix-file-for [toml_path: string]: nothing -> string {
    ($toml_path | path dirname) + "/default.nix"
}

def pkg-name-for [toml_path: string]: nothing -> string {
    $toml_path | path dirname | path basename
}

export def run-latest [toml_path: string]: nothing -> string {
    let cfg = (read-config $toml_path)
    match $cfg.source.type {
        "npm"    => { latest-from-npm $cfg.source.name }
        "github" => { latest-from-github $cfg.source.owner $cfg.source.repo }
        _ => {
            error make { msg: $"Unknown source.type: ($cfg.source.type)" }
        }
    }
}

export def run-update-files [toml_path: string, version: string]: nothing -> bool {
    let cfg = (read-config $toml_path)
    let pkg = (pkg-name-for $toml_path)
    let nix = (nix-file-for $toml_path)
    match $cfg.strategy.type {
        "fod" => {
            let layout = ($cfg.strategy | get -o platform_layout | default "suffix")
            update-fod {
                file:              $nix
                npm_name:          $cfg.source.name
                platform_suffixes: $cfg.strategy.platform_suffixes
                platform_layout:   $layout
            } $version
        }
        "multihash" => {
            update-multihash {
                file:       $nix
                hash_steps: $cfg.strategy.hash_steps
            } $pkg $version
        }
        _ => {
            error make { msg: $"Unknown strategy.type: ($cfg.strategy.type)" }
        }
    }
}
