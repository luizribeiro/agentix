#!/usr/bin/env nu

# Update a package to its latest npm version
#
# Usage: ./scripts/update-package.nu <package-name>
# Example: ./scripts/update-package.nu codex-cli

def package_config [package: string] {
    match $package {
        "codex-cli" => {
            npm_name: "@openai/codex",
            file: "packages/codex-cli/default.nix",
            type: "fod",
            platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"]
        },
        "claude-code" => {
            npm_name: "@anthropic-ai/claude-code",
            file: "packages/claude-code/default.nix",
            type: "fod",
            platform_suffixes: ["darwin-arm64", "linux-x64", "linux-arm64"],
            platform_layout: "subpackage"
        },
        "gemini-cli" => {
            npm_name: "@google/gemini-cli",
            file: "packages/gemini-cli/default.nix",
            type: "multihash",
            hash_steps: [["field", "label"]; ["hash", "source hash"], ["npmDepsHash", "npmDepsHash"]]
        },
        "antigravity-cli" => {
            manifest_base: "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests",
            file: "packages/antigravity-cli/default.nix",
            type: "manifest",
            platform_manifests: [
                [system, manifest];
                ["aarch64-darwin", "darwin_arm64"],
                ["x86_64-linux", "linux_amd64"],
                ["aarch64-linux", "linux_arm64"]
            ]
        },
        "crush" => {
            github_owner: "charmbracelet",
            github_repo: "crush",
            file: "packages/crush/default.nix",
            type: "multihash",
            hash_steps: [["field", "label"]; ["hash", "source hash"], ["vendorHash", "vendorHash"]]
        },
        "opencode" => {
            github_owner: "anomalyco",
            github_repo: "opencode",
            file: "packages/opencode/default.nix",
            type: "multihash",
            hash_steps: [["field", "label"]; ["hash", "source hash"], ["outputHash", "node_modules outputHash"]]
        },
        "pi" => {
            npm_name: "@mariozechner/pi-coding-agent",
            file: "packages/pi/default.nix",
            type: "multihash",
            hash_steps: [["field", "label"]; ["hash", "source hash"], ["npmDepsHash", "npmDepsHash"]],
            pre_update: "regen-pi-lockfile"
        },
        "roborev" => {
            github_owner: "roborev-dev",
            github_repo: "roborev",
            file: "packages/roborev/default.nix",
            type: "multihash",
            hash_steps: [["field", "label"]; ["hash", "source hash"], ["vendorHash", "vendorHash"]]
        },
        _ => {
            print $"Error: Unknown package '($package)'"
            print "Valid packages: codex-cli, claude-code, gemini-cli, antigravity-cli, crush, opencode, pi, roborev"
            exit 1
        }
    }
}

def main [package?: string] {
    if ($package | is-empty) {
        print "Error: missing package argument"
        print "Usage: ./scripts/update-package.nu <package-name>"
        exit 1
    }

    let package = $package
    let config = package_config $package

    # Fetch latest version
    let latest_version = if ($config.github_owner? | is-not-empty) {
        print $"Fetching latest version from GitHub ($config.github_owner)/($config.github_repo)..."
        let api_url = $"https://api.github.com/repos/($config.github_owner)/($config.github_repo)/releases/latest"
        let token = ($env.GITHUB_TOKEN? | default "")
        let response = if ($token | is-empty) {
            http get $api_url
        } else {
            http get --headers [Authorization $"Bearer ($token)"] $api_url
        }
        $response | get tag_name | str replace 'v' ''
    } else if ($config.manifest_base? | is-not-empty) {
        let first = ($config.platform_manifests | first)
        let manifest_url = $"($config.manifest_base)/($first.manifest).json"
        print $"Fetching latest version from ($manifest_url)..."
        http get $manifest_url | get version
    } else {
        print $"Fetching latest version for ($config.npm_name)..."
        let registry_url = $"https://registry.npmjs.org/($config.npm_name)"
        http get $registry_url | get dist-tags.latest
    }

    # Get current version from package file
    let current_version = (
        open $config.file
        | lines
        | where $it =~ 'version = '
        | first
        | str replace 'version = "' ''
        | str replace '";' ''
        | str trim
    )

    print $"Current: ($current_version)"
    print $"Latest:  ($latest_version)"

    if $current_version == $latest_version {

        print $"✓ ($package) is up to date"
        print "updated=false"
        return
    }

    print $"↻ Updating ($package) from ($current_version) to ($latest_version)"

    # Save original file content for rollback
    let original_content = open $config.file

    # Update based on package type
    let update_result = if $config.type == "fod" {
        update_fod_package $config $latest_version
    } else if $config.type == "manifest" {
        update_manifest_package $config $latest_version
    } else {
        update_multihash_package $config $package $latest_version $original_content
    }

    if not $update_result {
        print $"⚠ Could not update ($package) - build requirements not met"
        print "updated=false"
        return
    }

    # Update README.md with new version
    update_readme $package $latest_version

    print $"✓ Updated ($package) to ($latest_version)"
    print "updated=true"
    print $"current=($current_version)"
    print $"latest=($latest_version)"
}

# Update a Fixed Output Derivation package (codex-cli, claude-code)
def update_fod_package [config: record, version: string]: nothing -> bool {
    # Fetch tarball hash
    let pkg_name = ($config.npm_name | split row '/' | last)
    let tarball_url = $"https://registry.npmjs.org/($config.npm_name)/-/($pkg_name)-($version).tgz"
    print $"Fetching hash for ($tarball_url)..."

    let hash_output = (nix-prefetch-url $tarball_url | complete)
    if $hash_output.exit_code != 0 {
        print $"Error fetching hash: ($hash_output.stderr)"
        return false
    }

    let nix_hash = $hash_output.stdout | str trim
    let sri_hash = (nix hash convert --hash-algo sha256 $nix_hash | complete | get stdout | str trim)

    # Update version and main hash
    let content = open $config.file
    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($sri_hash)"'
    )

    $updated | save -f $config.file

    let platform_suffixes = if ($config.platform_suffixes? | is-not-empty) {
        $config.platform_suffixes
    } else {
        []
    }
    let platform_layout = ($config.platform_layout? | default "suffix")

    for suffix in $platform_suffixes {
        let new_hash_value = if $platform_layout == "subpackage" {
            let sub_pkg = $"($config.npm_name)-($suffix)"
            print $"Fetching integrity for ($sub_pkg)@($version)..."
            let meta = try {
                http get $"https://registry.npmjs.org/($sub_pkg)/($version)"
            } catch { |e|
                print $"Error fetching ($sub_pkg)@($version): ($e.msg)"
                return false
            }
            $meta | get dist.integrity
        } else {
            let platform_url = $"https://registry.npmjs.org/($config.npm_name)/-/($pkg_name)-($version)-($suffix).tgz"
            print $"Fetching platform hash for ($suffix)..."
            let platform_hash_output = (nix-prefetch-url $platform_url | complete)
            if $platform_hash_output.exit_code != 0 {
                print $"Error fetching platform hash for ($suffix): ($platform_hash_output.stderr)"
                return false
            }
            "sha256:" + ($platform_hash_output.stdout | str trim)
        }

        let regex_pattern = "(?s)(suffix = \"" + $suffix + "\";\\s*hash = \")sha(256|512)[-:][^\"]*\""
        let replacement = "${1}" + $new_hash_value + "\""

        let before = open $config.file
        let after = ($before | str replace -r $regex_pattern $replacement)
        if $before == $after {
            print $"Error: platform hash for ($suffix) — regex did not match. File format may have changed."
            return false
        }
        $after | save -f $config.file
    }

    true
}

# Update a package whose distribution is described by per-platform JSON manifests
# (e.g. antigravity-cli). Each manifest returns { version, url, sha512 } and the
# binary build ID (embedded in the URL) is updated once for all platforms.
def update_manifest_package [config: record, version: string]: nothing -> bool {
    mut entries = []
    for entry in $config.platform_manifests {
        let url = $"($config.manifest_base)/($entry.manifest).json"
        print $"Fetching manifest for ($entry.system)..."
        let manifest = try {
            http get $url
        } catch { |e|
            print $"Error fetching manifest for ($entry.system): ($e.msg)"
            return false
        }
        $entries = ($entries | append { system: $entry.system, manifest: $manifest })
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
        open $config.file
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'buildId = "[^"]*"' $'buildId = "($build_id)"'
    )

    for entry in $entries {
        let hex = $entry.manifest.sha512
        let convert_result = (nix hash convert --hash-algo sha512 --to sri $hex | complete)
        if $convert_result.exit_code != 0 {
            print $"Error converting sha512 for ($entry.system): ($convert_result.stderr)"
            return false
        }
        let sri = ($convert_result.stdout | str trim)

        let regex_pattern = "(?s)(\"" + $entry.system + "\" = \\{[^}]*hash = \")sha(256|512)[-:][^\"]*\""
        let replacement = "${1}" + $sri + "\""

        if not ($content =~ $regex_pattern) {
            print $"Error: platform hash for ($entry.system) — regex did not match. File format may have changed."
            return false
        }
        $content = ($content | str replace -r $regex_pattern $replacement)
    }

    $content | save -f $config.file
    true
}

def resolve_hash_by_build [
    file: string,
    package: string,
    field_name: string,
    label: string
]: nothing -> string {
    print $"Building to get ($label)..."
    let build_result = (nix build $".#($package)" --no-link | complete)
    let got_lines = (
        $build_result.stderr | lines | where $it =~ "got:"
    )

    if ($got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch for ($label). Build output:"
        print $build_result.stderr
        return ""
    }

    let real_hash = (
        $got_lines | first | str trim | split row "got:" | get 1 | str trim
    )

    if ($real_hash | is-empty) {
        print $"Error: Could not extract ($label)"
        return ""
    }

    let content = open $file
    let updated = (
        $content
        | str replace -r $'($field_name) = "sha256-[^"]*"' $'($field_name) = "($real_hash)"'
    )
    $updated | save -f $file

    print $"✓ ($label): ($real_hash)"
    $real_hash
}

def run_pre_update [hook: string, version: string]: nothing -> bool {
    match $hook {
        "regen-pi-lockfile" => {
            print "Regenerating packages/pi/package-lock.json..."
            let lockfile_cmd = (
                "set -euo pipefail; repo_root=$(pwd); tmp=$(mktemp -d); trap 'rm -rf \"$tmp\"' EXIT; "
                + "curl -L --fail -o \"$tmp/pi.tgz\" https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-"
                + $version
                + ".tgz >/dev/null; tar -xzf \"$tmp/pi.tgz\" -C \"$tmp\"; cd \"$tmp/package\"; "
                + "npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null; "
                + "cp package-lock.json \"$repo_root/packages/pi/package-lock.json\""
            )
            let result = (^bash -lc $lockfile_cmd | complete)
            if $result.exit_code != 0 {
                print $"Error in pre-update hook: ($result.stderr)"
                return false
            }
            true
        },
        _ => {
            print $"Error: Unknown pre-update hook '($hook)'"
            false
        }
    }
}

def update_multihash_package [config: record, package: string, version: string, original_content: string]: nothing -> bool {
    if ($config.pre_update? | is-not-empty) {
        if not (run_pre_update $config.pre_update $version) {
            return false
        }
    }

    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    mut content = (
        open $config.file
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
    )
    for step in $config.hash_steps {
        $content = ($content | str replace -r $'($step.field) = "sha256-[^"]*"' $'($step.field) = "($fake_hash)"')
    }
    $content | save -f $config.file

    for step in $config.hash_steps {
        let result = (resolve_hash_by_build $config.file $package $step.field $step.label)
        if ($result | is-empty) {
            $original_content | save -f $config.file
            return false
        }
    }

    true
}

# Update README.md with new version in the packages table
def update_readme [package: string, version: string] {
    let readme_path = "README.md"

    # Map package names to their README table row patterns
    let pattern = match $package {
        "codex-cli" => '| `codex-cli` | `codex` |',
        "claude-code" => '| `claude-code` | `claude` |',
        "gemini-cli" => '| `gemini-cli` | `gemini` |',
        "antigravity-cli" => '| `antigravity-cli` | `agy` |',
        "crush" => '| `crush` | `crush` |',
        "opencode" => '| `opencode` | `opencode` |',
        "pi" => '| `pi` | `pi` |',
        "roborev" => '| `roborev` | `roborev` |',
        _ => {
            print $"Warning: Unknown package ($package) for README update"
            return
        }
    }

    print $"Updating README.md version for ($package)..."

    let content = open --raw $readme_path
    let updated = (
        $content
        | lines
        | each { |line|
            if ($line | str starts-with $pattern) {
                # Replace the version number (third column) in the table row
                $line | str replace -r '\| ([0-9]+\.[0-9]+\.[0-9]+) \|' $'| ($version) |'
            } else {
                $line
            }
        }
        | str join (char newline)
    )

    $updated | save -f $readme_path
}
