use ../../scripts/update-lib *

export const README_ANCHOR = '| `codex-cli` | `codex` |'

export def latest-version []: nothing -> string {
    latest-from-npm "@openai/codex"
}

export def update-files [version: string]: nothing -> bool {
    update-fod {
        file: "packages/codex-cli/default.nix"
        npm_name: "@openai/codex"
        platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"]
    } $version
}

export def update-readme [version: string] {
    update-readme-row "codex-cli" $version $README_ANCHOR
}
