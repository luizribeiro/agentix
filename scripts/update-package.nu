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
        _ => {
            print $"Error: Unknown package '($package)'"
            print "Valid packages: codex-cli, claude-code, gemini-cli"
            exit 1
        }
    }

    # Fetch latest version from npm
    print $"Fetching latest version for ($config.npm_name)..."
    let registry_url = $"https://registry.npmjs.org/($config.npm_name)"
    let latest_version = (
        http get $registry_url
        | get dist-tags.latest
    )

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

    # Update based on package type
    if $config.type == "fod" {
        update_fod_package $config $latest_version
    } else {
        update_buildnpm_package $config $latest_version
    }

    # Update README.md with new version
    update_readme $package $latest_version

    print $"✓ Updated ($package) to ($latest_version)"
    print "updated=true"
    print $"current=($current_version)"
    print $"latest=($latest_version)"
}

# Update a Fixed Output Derivation package (codex-cli, claude-code)
def update_fod_package [config: record, version: string] {
    # Fetch tarball hash
    let tarball_url = $"https://registry.npmjs.org/($config.npm_name)/-/(($config.npm_name | split row '/' | last))-($version).tgz"
    print $"Fetching hash for ($tarball_url)..."

    let hash_output = (nix-prefetch-url $tarball_url | complete)
    if $hash_output.exit_code != 0 {
        print $"Error fetching hash: ($hash_output.stderr)"
        exit 1
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
}

# Update a buildNpmPackage (gemini-cli)
def update_buildnpm_package [config: record, version: string] {
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
    let src_hash = (
        $src_result.stderr
        | lines
        | find "got:"
        | first
        | parse "got:    {hash}"
        | get hash.0
        | str trim
    )

    if ($src_hash | is-empty) {
        print "Error: Could not extract source hash"
        exit 1
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
    let npm_hash = (
        $npm_result.stderr
        | lines
        | find "got:"
        | first
        | parse "got:    {hash}"
        | get hash.0
        | str trim
    )

    if ($npm_hash | is-empty) {
        print "Error: Could not extract npmDepsHash"
        exit 1
    }

    # Update npmDepsHash
    let content3 = open $config.file
    let updated3 = (
        $content3
        | str replace -r 'npmDepsHash = "sha256-[^"]*"' $'npmDepsHash = "($npm_hash)"'
    )
    $updated3 | save -f $config.file
}

# Update README.md with new version in the packages table
def update_readme [package: string, version: string] {
    let readme_path = "README.md"

    # Map package names to their README table row patterns
    let pattern = match $package {
        "codex-cli" => '| `codex-cli` | `codex` |',
        "claude-code" => '| `claude-code` | `claude` |',
        "gemini-cli" => '| `gemini-cli` | `gemini` |',
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
