use update-lib *

export const CONFIG = {
    source: { type: "npm", name: "@earendil-works/pi-coding-agent" }
    strategy: {
        type: "multihash"
        hash_steps: [
            { field: "hash",        label: "source hash" }
            { field: "npmDepsHash", label: "npmDepsHash" }
        ]
    }
}

# pi's tarball ships an npm-shrinkwrap.json that omits `integrity` for its six
# first-party @earendil-works/* packages, which fetch-npm-deps rejects. We drop
# it and regenerate a full lockfile from the registry instead.
#
# npm 11 is pinned because npm 10 (from the devshell's nodejs_22) crashes with
# "Cannot read properties of null (reading 'edgesOut')" resolving pi's nested
# `overrides` entry.
def regenerate-lockfile [version: string]: nothing -> bool {
    print "Regenerating packages/pi/package-lock.json..."
    let pkg = $CONFIG.source.name
    let tarball = $"https://registry.npmjs.org/($pkg)/-/($pkg | split row '/' | last)-($version).tgz"
    let cmd = (
        "set -euo pipefail; repo_root=$(pwd); tmp=$(mktemp -d); trap 'rm -rf \"$tmp\"' EXIT; "
        + "curl -L --fail -o \"$tmp/pi.tgz\" "
        + $tarball
        + " >/dev/null; tar -xzf \"$tmp/pi.tgz\" -C \"$tmp\"; cd \"$tmp/package\"; "
        + "rm -f npm-shrinkwrap.json; "
        + "npx -y npm@11 install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null; "
        + "cp package-lock.json \"$repo_root/packages/pi/package-lock.json\""
    )
    let result = (^bash -lc $cmd | complete)
    if $result.exit_code != 0 {
        print $"Error regenerating lockfile: ($result.stderr)"
        return false
    }
    true
}

# Override the declarative update-files to add the lockfile regen step
# before delegating to the standard multihash strategy.
export def update-files [version: string]: nothing -> bool {
    if not (regenerate-lockfile $version) { return false }
    update-files-from-config $CONFIG "pi" $version
}
