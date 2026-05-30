#!/usr/bin/env nu

# Dispatch to each package's own update module.
#
# Discovers `packages/<name>/update.nu` modules and invokes the matching
# one as a subprocess for both the latest-version query and the actual
# update (files + README, composed inline). Each module is a pure
# nushell module exporting `latest-version`, `update-files`, and
# `update-readme` — no `main` boilerplate per package.
#
# Usage: ./scripts/update-package.nu <package-name>

def discover-packages []: nothing -> list<string> {
    ls packages
        | where type == dir
        | get name
        | path basename
        | where {|p| ($"packages/($p)/update.nu" | path exists)}
        | sort
}

def read-current-version [file: string]: nothing -> string {
    open $file
        | lines
        | where $it =~ '^  version = "'
        | first
        | str replace 'version = "' ''
        | str replace '";' ''
        | str trim
}

def main [package?: string] {
    let packages = (discover-packages)

    if ($package | is-empty) {
        print "Error: missing package argument"
        print "Usage: ./scripts/update-package.nu <package-name>"
        print $"Valid packages: ($packages | str join ', ')"
        exit 1
    }

    if not ($package in $packages) {
        print $"Error: Unknown package '($package)'"
        print $"Valid packages: ($packages | str join ', ')"
        exit 1
    }

    let mod_path = $"packages/($package)/update.nu"
    let nix_file = $"packages/($package)/default.nix"

    print $"Fetching latest version for ($package)..."
    let latest = (^nu -c $"use ($mod_path) *; latest-version" | str trim)
    let current = (read-current-version $nix_file)

    print $"Current: ($current)"
    print $"Latest:  ($latest)"

    if $current == $latest {
        print $"✓ ($package) is up to date"
        print "updated=false"
        return
    }

    print $"↻ Updating ($package) from ($current) to ($latest)"

    # Compose update-files + update-readme in a single subprocess so we
    # pay the nushell-startup cost only once and so the README rewrite
    # is skipped automatically if the file rewrite fails.
    let combo = $"use ($mod_path) *; if \(update-files '($latest)'\) { update-readme '($latest)' } else { exit 1 }"
    let result = (^nu -c $combo | complete)
    print $result.stdout
    if $result.exit_code != 0 {
        if not ($result.stderr | is-empty) { print $result.stderr }
        print $"⚠ Could not update ($package)"
        print "updated=false"
        return
    }

    print $"✓ Updated ($package) to ($latest)"
    print "updated=true"
    print $"current=($current)"
    print $"latest=($latest)"
}
