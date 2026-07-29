# Hash discovery / format conversion helpers.

use rewrite.nu *

# Prefetch a tarball and return its SRI sha256.
export def prefetch-tarball-sri [url: string]: nothing -> string {
    let result = (nix-prefetch-url $url | complete)
    if $result.exit_code != 0 {
        error make { msg: $"nix-prefetch-url failed: ($result.stderr)" }
    }
    let nix_hash = ($result.stdout | str trim)
    nix hash convert --hash-algo sha256 $nix_hash | complete | get stdout | str trim
}

# Prefetch a tarball and return its legacy `sha256:<base32>` form.
# (Used by codex-cli for per-suffix platform tarballs.)
export def prefetch-tarball-base32 [url: string]: nothing -> string {
    let result = (nix-prefetch-url $url | complete)
    if $result.exit_code != 0 {
        error make { msg: $"nix-prefetch-url failed: ($result.stderr)" }
    }
    "sha256:" + ($result.stdout | str trim)
}

# Fetch the `dist.integrity` SRI hash for a specific npm package@version.
export def fetch-npm-integrity [name: string, version: string]: nothing -> string {
    http get $"https://registry.npmjs.org/($name)/($version)" | get dist.integrity
}

# Convert a hex digest into nix SRI format. `algo` is e.g. "sha256" or "sha512".
export def hex-to-sri [algo: string, hex: string]: nothing -> string {
    let result = (nix hash convert --hash-algo $algo --to sri $hex | complete)
    if $result.exit_code != 0 {
        error make { msg: $"nix hash convert failed: ($result.stderr)" }
    }
    $result.stdout | str trim
}

# Build the named flake output, expect a hash mismatch on `step`'s hash,
# and rewrite that hash in `file` to the real value extracted from the
# error output. Returns the new hash (or "" on failure).
export def resolve-hash-by-build [
    file: string
    package: string
    step: record
]: nothing -> string {
    print $"Building to get ($step.label)..."
    let build_result = (nix build $".#($package)" --no-link | complete)
    let got_lines = ($build_result.stderr | lines | where $it =~ "got:")

    if ($got_lines | is-empty) {
        print $"Error: Build failed without hash mismatch for ($step.label). Build output:"
        print $build_result.stderr
        return ""
    }

    let real_hash = (
        $got_lines | first | str trim | split row "got:" | get 1 | str trim
    )

    if ($real_hash | is-empty) {
        print $"Error: Could not extract ($step.label)"
        return ""
    }

    # Field steps anchor on the 2/4-space package-level depth so we don't
    # accidentally rewrite a same-named field nested deeper (e.g.
    # antigravity-cli's per-platform `hash = "sha512-…"` at 6-space).
    # A hash the step can't locate must fail here rather than silently
    # no-op — otherwise the next build step harvests this step's mismatch
    # into the wrong field.
    let content = open $file
    if not ($content | require-hash-step $step $file) {
        return ""
    }
    $content | rewrite-hash-step $step $real_hash | save -f $file

    print $"✓ ($step.label): ($real_hash)"
    $real_hash
}
