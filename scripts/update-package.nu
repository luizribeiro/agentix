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
            type: "fod"
        },
        "gemini-cli" => {
            npm_name: "@google/gemini-cli",
            file: "packages/gemini-cli/default.nix",
            type: "buildNpmPackage"
        },
        "crush" => {
            github_owner: "charmbracelet",
            github_repo: "crush",
            file: "packages/crush/default.nix",
            type: "buildGoModule"
        },
        "opencode" => {
            github_owner: "anomalyco",
            github_repo: "opencode",
            file: "packages/opencode/default.nix",
            type: "bunFod"
        },
        "pi" => {
            npm_name: "@mariozechner/pi-coding-agent",
            file: "packages/pi/default.nix",
            type: "buildNpmPackage"
        },
        _ => {
            print $"Error: Unknown package '($package)'"
            print "Valid packages: codex-cli, claude-code, gemini-cli, crush, opencode, pi"
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
    let latest_version = if $config.type == "buildGoModule" or $config.type == "bunFod" {
        print $"Fetching latest version from GitHub ($config.github_owner)/($config.github_repo)..."
        let api_url = $"https://api.github.com/repos/($config.github_owner)/($config.github_repo)/releases/latest"
        http get $api_url | get tag_name | str replace 'v' ''
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
    } else if $config.type == "buildNpmPackage" {
        update_buildnpm_package $config $package $latest_version $original_content
    } else if $config.type == "buildGoModule" {
        update_buildgo_package $config $latest_version $original_content
    } else {
        update_bunfod_package $config $latest_version $original_content
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

    # Update platform-specific hashes if present (e.g. codex-cli)
    let platform_suffixes = if ($config.platform_suffixes? | is-not-empty) {
        $config.platform_suffixes
    } else {
        []
    }

    for suffix in $platform_suffixes {
        let platform_url = $"https://registry.npmjs.org/($config.npm_name)/-/($pkg_name)-($version)-($suffix).tgz"
        print $"Fetching platform hash for ($suffix)..."

        let platform_hash_output = (nix-prefetch-url $platform_url | complete)
        if $platform_hash_output.exit_code != 0 {
            print $"Error fetching platform hash for ($suffix): ($platform_hash_output.stderr)"
            return false
        }

        let platform_nix_hash = $platform_hash_output.stdout | str trim

        let content2 = open $config.file
        let updated2 = (
            $content2
            | str replace -r $'(?s)(suffix = "($suffix)";\s*hash = ")sha256:[^"]*"' $'$1sha256:($platform_nix_hash)"'
        )
        $updated2 | save -f $config.file
    }

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

# Update a buildNpmPackage (gemini-cli, pi)
def update_buildnpm_package [config: record, package: string, version: string, original_content: string]: nothing -> bool {
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    if $package == "pi" {
        print "Regenerating packages/pi/package-lock.json..."
        let lockfile_cmd = (
            "set -euo pipefail; repo_root=$(pwd); tmp=$(mktemp -d); trap 'rm -rf \"$tmp\"' EXIT; "
            + "curl -L --fail -o \"$tmp/pi.tgz\" https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-"
            + $version
            + ".tgz >/dev/null; tar -xzf \"$tmp/pi.tgz\" -C \"$tmp\"; cd \"$tmp/package\"; "
            + "npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null; "
            + "cp package-lock.json \"$repo_root/packages/pi/package-lock.json\""
        )
        let lockfile_result = (^bash -lc $lockfile_cmd | complete)
        if $lockfile_result.exit_code != 0 {
            print "Error: Could not regenerate packages/pi/package-lock.json"
            print $lockfile_result.stderr
            return false
        }
    }

    (
        open $config.file
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($fake_hash)"'
        | str replace -r 'npmDepsHash = "sha256-[^"]*"' $'npmDepsHash = "($fake_hash)"'
    ) | save -f $config.file

    for step in [["field", "label"]; ["hash", "source hash"], ["npmDepsHash", "npmDepsHash"]] {
        let result = (resolve_hash_by_build $config.file $package $step.field $step.label)
        if ($result | is-empty) {
            $original_content | save -f $config.file
            return false
        }
    }

    true
}

# Update a buildGoModule package (crush)
def update_buildgo_package [config: record, version: string, original_content: string]: nothing -> bool {
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    let package = ($config.file | path dirname | path basename)

    (
        open $config.file
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($fake_hash)"'
        | str replace -r 'vendorHash = "sha256-[^"]*"' $'vendorHash = "($fake_hash)"'
    ) | save -f $config.file

    for step in [["field", "label"]; ["hash", "source hash"], ["vendorHash", "vendorHash"]] {
        let result = (resolve_hash_by_build $config.file $package $step.field $step.label)
        if ($result | is-empty) {
            $original_content | save -f $config.file
            return false
        }
    }

    true
}

# Update a bun-based Fixed Output Derivation package (opencode)
def update_bunfod_package [config: record, version: string, original_content: string]: nothing -> bool {
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    let package = ($config.file | path dirname | path basename)

    (
        open $config.file
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($fake_hash)"'
        | str replace -r 'outputHash = "sha256-[^"]*"' $'outputHash = "($fake_hash)"'
    ) | save -f $config.file

    for step in [["field", "label"]; ["hash", "source hash"], ["outputHash", "node_modules outputHash"]] {
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
        "crush" => '| `crush` | `crush` |',
        "opencode" => '| `opencode` | `opencode` |',
        "pi" => '| `pi` | `pi` |',
        _ => {
            print $"Warning: Unknown package ($package) for README update"
            return
        }
    }

    print $"Updating README.md version for ($package)..."

    let content = open $readme_path
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
