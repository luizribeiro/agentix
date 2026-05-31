# Generic runner for declarative `CONFIG` records exported from
# packages/<name>/update.nu. A package's update module can be:
#
#   pure declarative — only `export const CONFIG = { ... }`. The runner
#       computes `latest-version` and `update-files` from CONFIG.
#
#   pure custom — `export def latest-version` + `export def update-files`
#       with bodies that call lower-level lib helpers. No CONFIG.
#
#   mixed — `export const CONFIG = { ... }` PLUS one or both of
#       `export def latest-version` / `export def update-files`. The
#       function exports win where they exist; the runner is used for
#       whichever side delegates back to CONFIG.
#
# Expected CONFIG shape:
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

# Compute the latest upstream version from a config record.
export def latest-from-config [cfg: record]: nothing -> string {
    match $cfg.source.type {
        "npm"    => { latest-from-npm $cfg.source.name }
        "github" => { latest-from-github $cfg.source.owner $cfg.source.repo }
        _ => {
            error make { msg: $"Unknown source.type: ($cfg.source.type)" }
        }
    }
}

# Rewrite the package's default.nix to pin the given version, using the
# strategy declared in the config. `package` is the directory name; the
# default.nix path is derived from it.
export def update-files-from-config [cfg: record, package: string, version: string]: nothing -> bool {
    let nix = $"packages/($package)/default.nix"
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
            } $package $version
        }
        _ => {
            error make { msg: $"Unknown strategy.type: ($cfg.strategy.type)" }
        }
    }
}
