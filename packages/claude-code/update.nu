use ../../scripts/update-lib *

export const README_ANCHOR = '| `claude-code` | `claude` |'

export def latest-version []: nothing -> string {
    latest-from-npm "@anthropic-ai/claude-code"
}

export def update-files [version: string]: nothing -> bool {
    update-fod {
        file: "packages/claude-code/default.nix"
        npm_name: "@anthropic-ai/claude-code"
        platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"]
        platform_layout: "subpackage"
    } $version
}

export def update-readme [version: string] {
    update-readme-row "claude-code" $version $README_ANCHOR
}
