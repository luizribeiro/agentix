#!/usr/bin/env nu

# Dispatch to each package's own update module.
#
# Discovers `packages/<name>/update.nu` and invokes it as a subprocess for
# both the latest-version query and the actual update. Each module also
# exposes the same CLI surface (`nu packages/<name>/update.nu latest|update
# <version>`) so it can be driven directly during development.
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
        | where $it =~ 'version = '
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
    let latest = (^nu $mod_path latest | str trim)
    let current = (read-current-version $nix_file)

    print $"Current: ($current)"
    print $"Latest:  ($latest)"

    if $current == $latest {
        print $"✓ ($package) is up to date"
        print "updated=false"
        return
    }

    print $"↻ Updating ($package) from ($current) to ($latest)"

    let result = (^nu $mod_path update $latest | complete)
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
