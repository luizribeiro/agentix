#!/usr/bin/env nu

use ../../scripts/update-lib *

def latest-version []: nothing -> string {
    latest-from-npm "@openai/codex"
}

def do-update [version: string]: nothing -> bool {
    let ok = (update-fod {
        file: "packages/codex-cli/default.nix"
        npm_name: "@openai/codex"
        platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"]
    } $version)
    if not $ok { return false }
    update-readme-row "codex-cli" $version '| `codex-cli` | `codex` |'
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
