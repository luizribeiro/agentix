#!/usr/bin/env nu

# Put the nushell update library on the search path so per-package
# modules can `use update-lib *` without the relative ../../ traversal.
# The dispatcher itself lives in scripts/, so $env.FILE_PWD is exactly
# the directory we want NU_LIB_DIRS to point at.
#
# Set as a colon-separated STRING (not a list): when nushell spawns a
# child `^nu -c` process, only string-typed env vars survive the OS
# boundary. Child nushell then auto-parses NU_LIB_DIRS from the OS
# environment back into its own list. A list-typed parent $env.NU_LIB_DIRS
# silently fails to propagate.
$env.NU_LIB_DIRS = $env.FILE_PWD

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
        | where {|p| (($"packages/($p)/update.nu" | path exists) or ($"packages/($p)/update.toml" | path exists))}
        | sort
}

# Returns the `nu -c` strings the dispatcher should invoke for this
# package: { latest, files }. `files` carries the placeholder `<V>`
# which the caller substitutes with the resolved version.
#
# A package can use either an `update.nu` (custom) or an `update.toml`
# (declarative). `update.nu` wins when both exist so a package can start
# declarative and override later without renaming files.
#
# README rewriting is intentionally NOT a per-package concern; the
# dispatcher calls `render-readme.nu` once after the batch finishes so
# the table block in README.md regenerates from each default.nix's
# meta.{mainProgram,description}.
def invoke-spec [package: string]: nothing -> record {
    let mod_path  = $"packages/($package)/update.nu"
    let toml_path = $"packages/($package)/update.toml"
    if ($mod_path | path exists) {
        {
            latest: $"use ($mod_path) *; latest-version"
            files:  $"use ($mod_path) *; if not \(update-files '<V>'\) { exit 1 }"
        }
    } else if ($toml_path | path exists) {
        {
            latest: $"use update-lib *; run-latest '($toml_path)'"
            files:  $"use update-lib *; if not \(run-update-files '($toml_path)' '<V>'\) { exit 1 }"
        }
    } else {
        error make { msg: $"No update.nu or update.toml for ($package)" }
    }
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
    let nix_file = $"packages/($package)/default.nix"
    let spec = (invoke-spec $package)

    print $"Fetching latest version for ($package)..."
    let latest = (^nu -c $spec.latest | str trim)
    let current = (read-current-version $nix_file)

    print $"Current: ($current)"
    print $"Latest:  ($latest)"

    if $current == $latest {
        print $"✓ ($package) is up to date"
        print "updated=false"
        return { package: $package, status: "up-to-date", current: $current, latest: $latest }
    }

    print $"↻ Updating ($package) from ($current) to ($latest)"

    let files_cmd = ($spec.files | str replace -a '<V>' $latest)
    let result = (^nu -c $files_cmd | complete)
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

    # Regenerate README.md's package table once, after all per-package
    # rewrites are done. Cheap when nothing changed (idempotent).
    print ""
    ^nu $"($env.FILE_PWD)/render-readme.nu"

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
