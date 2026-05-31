#!/usr/bin/env nu

# Dispatch to each package's own update module.
#
# Discovers `packages/<name>/update.nu` modules and invokes the matching
# one as a subprocess for both the latest-version query and the actual
# update (files + README, composed inline). Each module is a pure
# nushell module exporting `latest-version`, `update-files`, and
# `update-readme` — no `main` boilerplate per package.
#
# Usage:
#   ./scripts/update-package.nu <package>           # one package
#   ./scripts/update-package.nu <p1> <p2> ...       # several packages
#   ./scripts/update-package.nu --all               # every discovered package

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

# Update a single package. Prints per-package output (current/latest, the
# updated=/current=/latest= grep-friendly lines preserved for parity with
# the CI matrix's expectations) and returns a status record the caller
# uses for the batch summary.
def update-one [package: string]: nothing -> record {
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
        return { package: $package, status: "up-to-date", current: $current, latest: $latest }
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
        return { package: $package, status: "failed", current: $current, latest: $latest }
    }

    print $"✓ Updated ($package) to ($latest)"
    print "updated=true"
    print $"current=($current)"
    print $"latest=($latest)"
    { package: $package, status: "updated", current: $current, latest: $latest }
}

def main [
    --all       # update every discovered package
    ...packages: string
] {
    let all_packages = (discover-packages)

    if $all and (not ($packages | is-empty)) {
        print "Error: pass either --all or a list of package names, not both"
        exit 1
    }

    let targets = if $all {
        $all_packages
    } else if ($packages | is-empty) {
        print "Error: missing package argument"
        print "Usage: ./scripts/update-package.nu [--all] <package>..."
        print $"Valid packages: ($all_packages | str join ', ')"
        exit 1
    } else {
        for pkg in $packages {
            if not ($pkg in $all_packages) {
                print $"Error: Unknown package '($pkg)'"
                print $"Valid packages: ($all_packages | str join ', ')"
                exit 1
            }
        }
        $packages
    }

    let is_batch = ($targets | length) > 1

    mut results = []
    for pkg in $targets {
        if $is_batch {
            if ($results | is-not-empty) { print "" }
            print $"=== ($pkg) ==="
        }
        $results = ($results | append (update-one $pkg))
    }

    if $is_batch {
        print ""
        print "=== summary ==="
        for r in $results {
            let glyph = match $r.status {
                "updated"    => "✓"
                "up-to-date" => "="
                "failed"     => "⚠"
                _            => "?"
            }
            let arrow = if $r.status == "updated" { $"($r.current) → ($r.latest)" } else { $r.current }
            print $"  ($glyph) ($r.package): ($arrow)"
        }
        let updated  = ($results | where status == "updated"    | length)
        let utd      = ($results | where status == "up-to-date" | length)
        let failed   = ($results | where status == "failed"     | length)
        print ""
        print $"($updated) updated, ($utd) up to date, ($failed) failed"
    }
}
