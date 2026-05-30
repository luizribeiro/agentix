# Pure string transforms over package default.nix contents.
#
# Each rewrite is pipe-style: the file contents flow through $in, and the
# remaining positional args are the rewrite parameters. Callers pipe
# `open file | rewrite-* ... | save -f file` so the I/O and rollback policy
# stays at the call site.

export def rewrite-version [v: string]: string -> string {
    $in | str replace -r 'version = "[^"]*"' $'version = "($v)"'
}

# Rewrite a `<field> = "<value>"` pair anywhere in the file. Use for plain
# scalar fields (e.g. buildId) and for the main hash field of FOD packages.
export def rewrite-field [field: string, value: string]: string -> string {
    $in | str replace -r $'($field) = "[^"]*"' $'($field) = "($value)"'
}

# Replace a hash whose location is uniquely identified by an `anchor_regex`
# ending right at the opening `"` of the existing hash value. The pattern
# accepts sha256 or sha512 in either SRI (`sha256-...`) or legacy
# (`sha256:...`) encoding.
export def rewrite-anchored-hash [anchor_regex: string, new_value: string]: string -> string {
    let pattern = "(?s)(" + $anchor_regex + ")sha(256|512)[-:][^\"]*\""
    let replacement = "${1}" + $new_value + "\""
    $in | str replace -r $pattern $replacement
}

# Probe whether the anchor regex matches anywhere — useful for telling apart
# "regex broken" from "match produced byte-identical output".
export def anchored-hash-matches? [anchor_regex: string]: string -> bool {
    let pattern = "(?s)(" + $anchor_regex + ")sha(256|512)[-:][^\"]*\""
    $in =~ $pattern
}
