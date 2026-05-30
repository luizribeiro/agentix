#!/usr/bin/env nu

use ../../scripts/update-lib *

def latest-version []: nothing -> string {
    latest-from-github "roborev-dev" "roborev"
}

def do-update [version: string]: nothing -> bool {
    let ok = (update-multihash {
        file: "packages/roborev/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [vendorHash, "vendorHash"]
        ]
    } "roborev" $version)
    if not $ok { return false }
    update-readme-row "roborev" $version '| `roborev` | `roborev` |'
    true
}

def main [command: string, version?: string] {
    match $command {
        "latest" => { print (latest-version) }
        "update" => {
            if ($version | is-empty) {
                print "Error: update requires a version argument"
                exit 2
            }
            if not (do-update $version) { exit 1 }
        }
        _ => {
            print $"Unknown command: ($command)"
            exit 2
        }
    }
}
