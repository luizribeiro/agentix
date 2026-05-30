#!/usr/bin/env nu

use ../../scripts/update-lib *

const README_ANCHOR = '| `codex-cli` | `codex` |'

def latest-version []: nothing -> string {
    latest-from-npm "@openai/codex"
}

def update-files [version: string]: nothing -> bool {
    update-fod {
        file: "packages/codex-cli/default.nix"
        npm_name: "@openai/codex"
        platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"]
    } $version
}

def update-readme [version: string] {
    update-readme-row "codex-cli" $version $README_ANCHOR
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
