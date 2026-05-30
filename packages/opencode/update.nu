use ../../scripts/update-lib *

export const README_ANCHOR = '| `opencode` | `opencode` |'

export def latest-version []: nothing -> string {
    latest-from-github "anomalyco" "opencode"
}

export def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/opencode/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [outputHash, "node_modules outputHash"]
        ]
    } "opencode" $version
}

export def update-readme [version: string] {
    update-readme-row "opencode" $version $README_ANCHOR
}
