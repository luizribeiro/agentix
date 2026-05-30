#!/usr/bin/env nu

use ../../scripts/update-lib *

const README_ANCHOR = '| `gemini-cli` | `gemini` |'

def latest-version []: nothing -> string {
    latest-from-npm "@google/gemini-cli"
}

def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/gemini-cli/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [npmDepsHash, "npmDepsHash"]
        ]
    } "gemini-cli" $version
}

def update-readme [version: string] {
    update-readme-row "gemini-cli" $version $README_ANCHOR
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
