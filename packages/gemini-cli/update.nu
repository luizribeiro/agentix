#!/usr/bin/env nu

use ../../scripts/update-lib *

def latest-version []: nothing -> string {
    latest-from-npm "@google/gemini-cli"
}

def do-update [version: string]: nothing -> bool {
    let ok = (update-multihash {
        file: "packages/gemini-cli/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [npmDepsHash, "npmDepsHash"]
        ]
    } "gemini-cli" $version)
    if not $ok { return false }
    update-readme-row "gemini-cli" $version '| `gemini-cli` | `gemini` |'
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
