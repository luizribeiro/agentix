# Pure string transforms over package default.nix contents.
#
# Each rewrite is pipe-style: the file contents flow through $in, and the
# remaining positional args are the rewrite parameters. Callers pipe
# `open file | rewrite-* ... | save -f file` so the I/O and rollback policy
# stays at the call site.
#
# Indent convention used for anchoring:
#   - The package's own `version` lives at 2-space indent in the let
#     binding. A `version` nested inside a sub-attrset or a builder
#     override sits deeper. rewrite-version targets 2-space only.
#   - Package-level scalar fields (hash, vendorHash, npmDepsHash,
#     outputHash, buildId, …) live at either 2-space (top-level rec body)
#     or 4-space (inside `src = fetchurl { … }`). Nested fields inside
#     platformInfo attrsets are 6+-space.
#     rewrite-field matches 2-or-4 only — a hash that genuinely nests
#     deeper needs an anchor step (see rewrite-hash-step), not a wider
#     depth regex.

export def rewrite-version [v: string]: string -> string {
    let replacement = '  version = "' + $v + '"'
    $in | str replace -r '(?m)^  version = "[^"]*"' $replacement
}

def field-pattern [field: string]: nothing -> string {
    '(?m)^( {2}| {4})' + $field + ' = "[^"]*"'
}

# Rewrite a `<field> = "<value>"` pair at the package-level depth
# (2- or 4-space indent). Use for plain scalar fields and for the main
# hash field of FOD packages.
export def rewrite-field [field: string, value: string]: string -> string {
    let replacement = '${1}' + $field + ' = "' + $value + '"'
    $in | str replace -r (field-pattern $field) $replacement
}

# Probe whether rewrite-field would match anything. str replace silently
# returns its input unchanged on no match, so callers that need a rewrite
# to happen must check this first.
export def field-matches? [field: string]: string -> bool {
    $in =~ (field-pattern $field)
}

def anchored-hash-pattern [anchor_regex: string]: nothing -> string {
    "(?s)(" + $anchor_regex + ")sha(256|512)[-:][^\"]*\""
}

# Replace a hash whose location is uniquely identified by an `anchor_regex`
# ending right at the opening `"` of the existing hash value. The pattern
# accepts sha256 or sha512 in either SRI (`sha256-...`) or legacy
# (`sha256:...`) encoding.
export def rewrite-anchored-hash [anchor_regex: string, new_value: string]: string -> string {
    let replacement = "${1}" + $new_value + "\""
    $in | str replace -r (anchored-hash-pattern $anchor_regex) $replacement
}

# Probe whether the anchor regex matches anywhere — useful for telling apart
# "regex broken" from "match produced byte-identical output".
export def anchored-hash-matches? [anchor_regex: string]: string -> bool {
    $in =~ (anchored-hash-pattern $anchor_regex)
}

# A multihash step is `{ field, label }` or `{ anchor, label }`. Field
# steps rewrite `<field> = "…"` at the package-level depth; anchor steps
# rewrite the hash their regex ends at, however deeply it nests (e.g.
# gemini-cli's src hash inside applyPatches → fetchFromGitHub).
export def rewrite-hash-step [step: record, value: string]: string -> string {
    if ($step.anchor? | is-empty) {
        $in | rewrite-field $step.field $value
    } else {
        $in | rewrite-anchored-hash $step.anchor $value
    }
}

export def hash-step-matches? [step: record]: string -> bool {
    if ($step.anchor? | is-empty) {
        $in | field-matches? $step.field
    } else {
        $in | anchored-hash-matches? $step.anchor
    }
}

# Guard for callers about to rewrite-hash-step: str replace silently
# returns its input unchanged on no match, so a step whose hash can't be
# located must abort the update instead of proceeding on stale content.
export def require-hash-step [step: record, file: string]: string -> bool {
    if ($in | hash-step-matches? $step) {
        true
    } else {
        print $"Error: ($step.label) — hash not found in ($file). File format may have changed."
        false
    }
}
