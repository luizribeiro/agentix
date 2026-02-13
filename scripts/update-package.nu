#!/usr/bin/env nu

# Update a package to its latest npm version
#
# Usage: ./scripts/update-package.nu <package-name>
# Example: ./scripts/update-package.nu codex-cli

def main [package: string] {
    # Package configuration
    let config = match $package {
        "codex-cli" => {
            npm_name: "@openai/codex",
            file: "packages/codex-cli/default.nix",
            type: "fod"
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
            type: "npmFod"
        },
        "gondolin" => {
            npm_name: "@earendil-works/gondolin",
            file: "packages/gondolin/default.nix",
            type: "npmFod"
        },
        _ => {
            print $"Error: Unknown package '($package)'"
            print "Valid packages: codex-cli, claude-code, gemini-cli, crush, opencode, pi, gondolin"
            exit 1
        }
    }

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
    } else if $config.type == "npmFod" {
        update_npmfod_package $config $package $latest_version $original_content
    } else if $config.type == "buildNpmPackage" {
        update_buildnpm_package $config $latest_version $original_content
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
    let tarball_url = $"https://registry.npmjs.org/($config.npm_name)/-/(($config.npm_name | split row '/' | last))-($version).tgz"
    print $"Fetching hash for ($tarball_url)..."

    let hash_output = (nix-prefetch-url $tarball_url | complete)
    if $hash_output.exit_code != 0 {
        print $"Error fetching hash: ($hash_output.stderr)"
        return false
    }

    let nix_hash = $hash_output.stdout | str trim
    let sri_hash = (nix hash convert --hash-algo sha256 $nix_hash | complete | get stdout | str trim)

    # Update version
    let content = open $config.file
    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($sri_hash)"'
    )

    $updated | save -f $config.file
    true
}

# Update an npm FOD package (pi, gondolin) - has fetchurl hash + per-platform outputHash for node_modules
def update_npmfod_package [config: record, package: string, version: string, original_content: string]: nothing -> bool {
    let system = (nix eval --impure --expr builtins.currentSystem --raw | complete | get stdout | str trim)
    print $"Detected system: ($system)"

    let tarball_url = $"https://registry.npmjs.org/($config.npm_name)/-/(($config.npm_name | split row '/' | last))-($version).tgz"
    print $"Fetching hash for ($tarball_url)..."

    let hash_output = (nix-prefetch-url $tarball_url | complete)
    if $hash_output.exit_code != 0 {
        print $"Error fetching hash: ($hash_output.stderr)"
        return false
    }

    let nix_hash = $hash_output.stdout | str trim
    let sri_hash = (nix hash convert --hash-algo sha256 $nix_hash | complete | get stdout | str trim)
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    let content = open $config.file
    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r '(?s)(src = fetchurl \{.*?hash = )"sha256-[^"]*"' $'$1"($sri_hash)"'
        | str replace -r $'"($system)" = "sha256-[^"]*"' $'"($system)" = "($fake_hash)"'
    )

    $updated | save -f $config.file

    print $"Building to get node_modules outputHash for ($system)..."
    let fod_result = (nix build $".#($package)" --no-link | complete)
    let fod_got_lines = (
        $fod_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($fod_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $fod_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let fod_hash = (
        $fod_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($fod_hash | is-empty) {
        print "Error: Could not extract outputHash"
        $original_content | save -f $config.file
        return false
    }

    let content2 = open $config.file
    let updated2 = (
        $content2
        | str replace $'"($system)" = "($fake_hash)"' $'"($system)" = "($fod_hash)"'
    )
    $updated2 | save -f $config.file
    true
}

# Update a buildNpmPackage (gemini-cli)
def update_buildnpm_package [config: record, version: string, original_content: string]: nothing -> bool {
    # Update version and set fake hashes
    let content = open $config.file
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($fake_hash)"'
        | str replace -r 'npmDepsHash = "sha256-[^"]*"' $'npmDepsHash = "($fake_hash)"'
    )

    $updated | save -f $config.file

    # Build to get source hash
    print "Building to get source hash..."
    let src_result = (nix build .#gemini-cli --no-link | complete)
    let src_got_lines = (
        $src_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($src_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $src_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let src_hash = (
        $src_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($src_hash | is-empty) {
        print "Error: Could not extract source hash"
        $original_content | save -f $config.file
        return false
    }

    # Update source hash
    let content2 = open $config.file
    let updated2 = (
        $content2
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($src_hash)"'
    )
    $updated2 | save -f $config.file

    # Build to get npmDepsHash
    print "Building to get npmDepsHash..."
    let npm_result = (nix build .#gemini-cli --no-link | complete)
    let npm_got_lines = (
        $npm_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($npm_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $npm_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let npm_hash = (
        $npm_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($npm_hash | is-empty) {
        print "Error: Could not extract npmDepsHash"
        $original_content | save -f $config.file
        return false
    }

    # Update npmDepsHash
    let content3 = open $config.file
    let updated3 = (
        $content3
        | str replace -r 'npmDepsHash = "sha256-[^"]*"' $'npmDepsHash = "($npm_hash)"'
    )
    $updated3 | save -f $config.file
    true
}

# Update a buildGoModule package (crush)
def update_buildgo_package [config: record, version: string, original_content: string]: nothing -> bool {
    # Update version and set fake hashes
    let content = open $config.file
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($fake_hash)"'
        | str replace -r 'vendorHash = "sha256-[^"]*"' $'vendorHash = "($fake_hash)"'
    )

    $updated | save -f $config.file

    # Build to get source hash
    print "Building to get source hash..."
    let src_result = (nix build .#crush --no-link | complete)
    let src_got_lines = (
        $src_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($src_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $src_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let src_hash = (
        $src_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($src_hash | is-empty) {
        print "Error: Could not extract source hash"
        $original_content | save -f $config.file
        return false
    }

    # Update source hash
    let content2 = open $config.file
    let updated2 = (
        $content2
        | str replace -r 'hash = "sha256-[^"]*"' $'hash = "($src_hash)"'
    )
    $updated2 | save -f $config.file

    # Build to get vendorHash
    print "Building to get vendorHash..."
    let vendor_result = (nix build .#crush --no-link | complete)
    let vendor_got_lines = (
        $vendor_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($vendor_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $vendor_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let vendor_hash = (
        $vendor_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($vendor_hash | is-empty) {
        print "Error: Could not extract vendorHash"
        $original_content | save -f $config.file
        return false
    }

    # Update vendorHash
    let content3 = open $config.file
    let updated3 = (
        $content3
        | str replace -r 'vendorHash = "sha256-[^"]*"' $'vendorHash = "($vendor_hash)"'
    )
    $updated3 | save -f $config.file
    true
}

# Update a bun-based Fixed Output Derivation package (opencode)
def update_bunfod_package [config: record, version: string, original_content: string]: nothing -> bool {
    # Update version and set fake hashes
    let content = open $config.file
    let fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    let updated = (
        $content
        | str replace -r 'version = "[^"]*"' $'version = "($version)"'
        | str replace -r '(src = fetchFromGitHub \{[^}]*hash = )"sha256-[^"]*"' $'$1"($fake_hash)"'
        | str replace -r 'outputHash = "sha256-[^"]*"' $'outputHash = "($fake_hash)"'
    )

    $updated | save -f $config.file

    # Build to get source hash
    print "Building to get source hash..."
    let src_result = (nix build .#opencode --no-link | complete)
    let src_got_lines = (
        $src_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($src_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $src_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let src_hash = (
        $src_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($src_hash | is-empty) {
        print "Error: Could not extract source hash"
        $original_content | save -f $config.file
        return false
    }

    # Update source hash
    let content2 = open $config.file
    let updated2 = (
        $content2
        | str replace -r '(src = fetchFromGitHub \{[^}]*hash = )"sha256-[^"]*"' $'$1"($src_hash)"'
    )
    $updated2 | save -f $config.file

    # Build to get outputHash (node_modules FOD)
    print "Building to get node_modules outputHash..."
    let fod_result = (nix build .#opencode --no-link | complete)
    let fod_got_lines = (
        $fod_result.stderr
        | lines
        | where $it =~ "got:"
    )

    if ($fod_got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch. Build output:"
        print $fod_result.stderr
        $original_content | save -f $config.file
        return false
    }

    let fod_hash = (
        $fod_got_lines
        | first
        | str trim
        | split row "got:"
        | get 1
        | str trim
    )

    if ($fod_hash | is-empty) {
        print "Error: Could not extract outputHash"
        $original_content | save -f $config.file
        return false
    }

    # Update outputHash
    let content3 = open $config.file
    let updated3 = (
        $content3
        | str replace -r 'outputHash = "sha256-[^"]*"' $'outputHash = "($fod_hash)"'
    )
    $updated3 | save -f $config.file
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
        "gondolin" => '| `gondolin` | `gondolin` |',
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
