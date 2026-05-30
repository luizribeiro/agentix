use ../../scripts/update-lib *

export const README_ANCHOR = '| `gemini-cli` | `gemini` |'

export def latest-version []: nothing -> string {
    latest-from-npm "@google/gemini-cli"
}

export def update-files [version: string]: nothing -> bool {
    update-multihash {
        file: "packages/gemini-cli/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [npmDepsHash, "npmDepsHash"]
        ]
    } "gemini-cli" $version
}

export def update-readme [version: string] {
    update-readme-row "gemini-cli" $version $README_ANCHOR
}
