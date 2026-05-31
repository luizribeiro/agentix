use update-lib *

export const README_ANCHOR = '| `pi` | `pi` |'

# pi ships without a package-lock.json in its npm tarball, so we regenerate
# one from the published tarball before letting update-multihash compute
# npmDepsHash. Without this the build can't reproduce the node_modules tree.
def regenerate-lockfile [version: string]: nothing -> bool {
    print "Regenerating packages/pi/package-lock.json..."
    let cmd = (
        "set -euo pipefail; repo_root=$(pwd); tmp=$(mktemp -d); trap 'rm -rf \"$tmp\"' EXIT; "
        + "curl -L --fail -o \"$tmp/pi.tgz\" https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-"
        + $version
        + ".tgz >/dev/null; tar -xzf \"$tmp/pi.tgz\" -C \"$tmp\"; cd \"$tmp/package\"; "
        + "npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null; "
        + "cp package-lock.json \"$repo_root/packages/pi/package-lock.json\""
    )
    let result = (^bash -lc $cmd | complete)
    if $result.exit_code != 0 {
        print $"Error regenerating lockfile: ($result.stderr)"
        return false
    }
    true
}

export def latest-version []: nothing -> string {
    latest-from-npm "@mariozechner/pi-coding-agent"
}

export def update-files [version: string]: nothing -> bool {
    if not (regenerate-lockfile $version) { return false }
    update-multihash {
        file: "packages/pi/default.nix"
        hash_steps: [
            [field, label];
            [hash, "source hash"]
            [npmDepsHash, "npmDepsHash"]
        ]
    } "pi" $version
}

export def update-readme [version: string] {
    update-readme-row "pi" $version $README_ANCHOR
}
