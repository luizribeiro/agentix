use ../../scripts/update-lib *

export const README_ANCHOR = '| `crush` | `crush` |'

export def latest-version []: nothing -> string {
    latest-from-github "charmbracelet" "crush"
}

export def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/crush/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [vendorHash, "vendorHash"]
        ]
    } "crush" $version
}

export def update-readme [version: string] {
    update-readme-row "crush" $version $README_ANCHOR
}
