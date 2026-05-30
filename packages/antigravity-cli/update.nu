use ../../scripts/update-lib *

# Antigravity ships closed-source prebuilt binaries through Google's own
# auto-updater endpoint (no GitHub releases, no npm). Each per-platform
# manifest carries the version, a CDN URL with an embedded build ID, and
# the sha512 of the tarball. The shape is bespoke enough that it lives
# here rather than being promoted into a shared strategy.

const MANIFEST_BASE = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests"
const PLATFORMS = [
    [system, manifest];
    [aarch64-darwin, darwin_arm64]
    [x86_64-linux, linux_amd64]
    [aarch64-linux, linux_arm64]
]
const FILE = "packages/antigravity-cli/default.nix"

export const README_ANCHOR = '| `antigravity-cli` | `agy` |'

export def latest-version []: nothing -> string {
    let first = ($PLATFORMS | first)
    http get $"($MANIFEST_BASE)/($first.manifest).json" | get version
}

export def update-files [version: string]: nothing -> bool {
    mut entries = []
    for p in $PLATFORMS {
        let url = $"($MANIFEST_BASE)/($p.manifest).json"
        print $"Fetching manifest for ($p.system)..."
        let m = try {
            http get $url
        } catch { |e|
            print $"Error fetching manifest for ($p.system): ($e.msg)"
            return false
        }
        $entries = ($entries | append { system: $p.system, manifest: $m })
    }

    let versions = ($entries | each {|e| $e.manifest.version} | uniq)
    if ($versions | length) > 1 {
        print $"Error: platform manifests disagree on version: ($versions)"
        return false
    }

    # URL shape: .../antigravity-cli/<buildId>/<platform>/cli_*.tar.gz
    let first_url = ($entries | first | get manifest.url)
    let parts = ($first_url | split row '/')
    let cli_idx = ($parts | enumerate | where item == "antigravity-cli" | get 0.index?)
    if ($cli_idx | is-empty) {
        print $"Error: could not locate 'antigravity-cli' segment in URL ($first_url)"
        return false
    }
    let build_id = ($parts | get ($cli_idx + 1))

    mut content = (
        open $FILE
        | rewrite-version $version
        | rewrite-field "buildId" $build_id
    )

    for e in $entries {
        let sri = (hex-to-sri "sha512" $e.manifest.sha512)
        let anchor = "\"" + $e.system + "\" = \\{[^}]*hash = \""
        if not ($content | anchored-hash-matches? $anchor) {
            print $"Error: platform hash for ($e.system) — regex did not match. File format may have changed."
            return false
        }
        $content = ($content | rewrite-anchored-hash $anchor $sri)
    }

    $content | save -f $FILE
    true
}

export def update-readme [version: string] {
    update-readme-row "antigravity-cli" $version $README_ANCHOR
}
