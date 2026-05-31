#!/usr/bin/env nu

# Regenerate the package table in README.md from each package's
# default.nix. Reads version (2-space-indent line), meta.mainProgram,
# and meta.description — making default.nix the single source of truth
# instead of having the same data live in two places.
#
# The table block is delimited by HTML comments:
#
#     <!-- BEGIN package-table -->
#     | Package | Binary | Version | Description |
#     | ... regenerated ... |
#     <!-- END package-table -->
#
# Anything outside those markers is preserved.
#
# Usage:
#   ./scripts/render-readme.nu          # rewrites README.md in place
#   ./scripts/render-readme.nu --check  # exits 1 if README.md is stale

const README_PATH = "README.md"
const BEGIN_MARKER = "<!-- BEGIN package-table -->"
const END_MARKER   = "<!-- END package-table -->"

def discover-packages []: nothing -> list<string> {
    ls packages
        | where type == dir
        | get name
        | path basename
        | where {|p| ($"packages/($p)/default.nix" | path exists)}
        | sort
}

# Extract a single-line `name = "value";` field from a nix file.
def read-nix-field [file: string, field: string]: nothing -> string {
    let pattern = '.*' + $field + ' = "([^"]+)".*'
    open --raw $file
        | lines
        | where $it =~ $field
        | each {|line| $line | str replace -r $pattern '$1' }
        | get 0?
        | default ""
}

# Read the package's own version (2-space-indent let-binding) so nested
# `version = "…"` lines (e.g. crush's go-toolchain pin at 4-space) don't
# trip the regex.
def read-version [file: string]: nothing -> string {
    open --raw $file
        | lines
        | where $it =~ '^  version = "'
        | first
        | str replace -r '^  version = "([^"]+)";.*' '$1'
}

def render-row [package: string]: nothing -> string {
    let nix = $"packages/($package)/default.nix"
    let version = (read-version $nix)
    let bin     = (read-nix-field $nix "mainProgram")
    let desc    = (read-nix-field $nix "description")
    $"| `($package)` | `($bin)` | ($version) | ($desc) |"
}

def render-table []: nothing -> string {
    let rows = (discover-packages | each {|p| render-row $p })
    [
        "| Package | Binary | Version | Description |"
        "|---------|--------|---------|-------------|"
        ...$rows
        "| `default` | all | - | Combined package with all tools |"
    ] | str join (char newline)
}

def regenerate [content: string]: nothing -> string {
    let begin_idx = ($content | str index-of $BEGIN_MARKER)
    let end_idx   = ($content | str index-of $END_MARKER)
    if $begin_idx < 0 or $end_idx < 0 {
        error make { msg: $"README.md is missing the ($BEGIN_MARKER) / ($END_MARKER) markers" }
    }
    let prefix = ($content | str substring 0..($begin_idx + ($BEGIN_MARKER | str length)))
    let suffix = ($content | str substring $end_idx..)
    let table  = (render-table)
    $prefix + (char newline) + $table + (char newline) + $suffix
}

def main [--check] {
    let current = (open --raw $README_PATH)
    let updated = (regenerate $current)
    if $check {
        if $current == $updated {
            print "README.md is up to date"
        } else {
            print "README.md is stale; run ./scripts/render-readme.nu to regenerate"
            exit 1
        }
    } else {
        $updated | save -f $README_PATH
        if $current == $updated {
            print "README.md already up to date"
        } else {
            print "Regenerated README.md package table"
        }
    }
}
