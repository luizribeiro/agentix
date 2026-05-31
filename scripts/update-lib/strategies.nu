# Reusable update strategies. Packages with bespoke distribution models can
# skip these and write their `update-files` function inline using the
# lower-level helpers in registry.nu / hashes.nu / rewrite.nu.

use hashes.nu *
use rewrite.nu *

# Fixed-output-derivation strategy (codex-cli, claude-code).
#
# config: {
#   file: string                       — path to default.nix
#   npm_name: string                   — e.g. "@openai/codex"
#   platform_suffixes: list<string>    — e.g. ["darwin-arm64", "linux-x64", "linux-arm64"]
#   platform_layout?: "suffix" | "subpackage"  — defaults to "suffix"
# }
export def update-fod [config: record, version: string]: nothing -> bool {
    let pkg_name = ($config.npm_name | split row '/' | last)
    let tarball_url = $"https://registry.npmjs.org/($config.npm_name)/-/($pkg_name)-($version).tgz"
    print $"Fetching hash for ($tarball_url)..."

    let sri_hash = try {
        prefetch-tarball-sri $tarball_url
    } catch { |e|
        print $"Error fetching hash: ($e.msg)"
        return false
    }

    open $config.file
        | rewrite-version $version
        | rewrite-field "hash" $sri_hash
        | save -f $config.file

    let platform_layout = ($config.platform_layout? | default "suffix")
    let suffixes = ($config.platform_suffixes? | default [])

    for suffix in $suffixes {
        let new_hash_value = if $platform_layout == "subpackage" {
            let sub = $"($config.npm_name)-($suffix)"
            print $"Fetching integrity for ($sub)@($version)..."
            try {
                fetch-npm-integrity $sub $version
            } catch { |e|
                print $"Error fetching ($sub)@($version): ($e.msg)"
                return false
            }
        } else {
            let url = $"https://registry.npmjs.org/($config.npm_name)/-/($pkg_name)-($version)-($suffix).tgz"
            print $"Fetching platform hash for ($suffix)..."
            try {
                prefetch-tarball-base32 $url
            } catch { |e|
                print $"Error fetching platform hash for ($suffix): ($e.msg)"
                return false
            }
        }

        let anchor = "suffix = \"" + $suffix + "\";\\s*hash = \""
        let before = open $config.file
        if not ($before | anchored-hash-matches? $anchor) {
            print $"Error: platform hash for ($suffix) — regex did not match. File format may have changed."
            return false
        }
        $before | rewrite-anchored-hash $anchor $new_hash_value | save -f $config.file
    }

    true
}

# Build-driven hash discovery (gemini-cli, crush, opencode, pi, roborev).
# Writes fake hashes, builds the flake output for each field, and harvests
# the real hash from nix's "got:" error line via resolve-hash-by-build.
#
# config: {
#   file: string                                 — path to default.nix
#   hash_steps: table<field: string, label: string>
# }
#
# Rolls back the file to its original contents if any hash step fails.
export def update-multihash [config: record, package: string, version: string]: nothing -> bool {
    let original_content = open $config.file
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    mut content = ($original_content | rewrite-version $version)
    for step in $config.hash_steps {
        $content = ($content | rewrite-field $step.field $fake_hash)
    }
    $content | save -f $config.file

    for step in $config.hash_steps {
        let result = (resolve-hash-by-build $config.file $package $step.field $step.label)
        if ($result | is-empty) {
            $original_content | save -f $config.file
            return false
        }
    }

    true
}
