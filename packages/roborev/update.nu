#!/usr/bin/env nu

use ../../scripts/update-lib *

const README_ANCHOR = '| `roborev` | `roborev` |'

def latest-version []: nothing -> string {
    latest-from-github "roborev-dev" "roborev"
}

def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/roborev/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [vendorHash, "vendorHash"]
        ]
    } "roborev" $version
}

def update-readme [version: string] {
    update-readme-row "roborev" $version $README_ANCHOR
}

def main [command: string, version?: string] {
    match $command {
        "latest" => { print (latest-version) }
        "readme-anchor" => { print $README_ANCHOR }
        "update-files" => {
            if ($version | is-empty) { print "Error: version required"; exit 2 }
            if not (update-files $version) { exit 1 }
        }
        "update-readme" => {
            if ($version | is-empty) { print "Error: version required"; exit 2 }
            update-readme $version
        }
        "update" => {
            if ($version | is-empty) { print "Error: version required"; exit 2 }
            if not (update-files $version) { exit 1 }
            update-readme $version
        }
        _ => { print $"Unknown command: ($command)"; exit 2 }
    }
}
