use ../../scripts/update-lib *

export const README_ANCHOR = '| `roborev` | `roborev` |'

export def latest-version []: nothing -> string {
    latest-from-github "roborev-dev" "roborev"
}

export def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/roborev/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [vendorHash, "vendorHash"]
        ]
    } "roborev" $version
}

export def update-readme [version: string] {
    update-readme-row "roborev" $version $README_ANCHOR
}
