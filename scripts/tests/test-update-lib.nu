#!/usr/bin/env nu

# Unit tests for the pure rewrite helpers and for update-multihash's
# refusal to proceed when a hash it must rewrite can't be located.
# Everything runs on in-memory fixtures or sandbox files — no case
# reaches the network or invokes nix.
#
# Usage: nu scripts/tests/test-update-lib.nu

const LIB = (path self ../update-lib)
use $LIB *

# Shaped like gemini-cli's default.nix: the src hash sits at 6-space
# depth inside applyPatches → fetchFromGitHub, below the 2/4-space
# package-level depth that rewrite-field targets.
const NESTED_SRC_FIXTURE = '{
  pname = "gemini-cli";
  version = "0.50.0";

  src = applyPatches {
    name = "gemini-cli-src";
    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-nestedsourcehash=";
    };
  };

  npmDepsHash = "sha256-npmdepshash=";
}'

# Shaped like a plain FOD package: src hash at 4-space depth.
const FLAT_SRC_FIXTURE = '{
  pname = "claude-code";
  version = "1.0.0";

  src = fetchurl {
    url = "https://example.com/pkg.tgz";
    hash = "sha256-flatsourcehash=";
  };
}'

def check [label: string, ok: bool]: nothing -> bool {
    if $ok {
        print $"✓ ($label)"
    } else {
        print $"✗ ($label)"
    }
    $ok
}

# Keep in sync with packages/gemini-cli/update.nu. The fixture's tag line
# interpolates ${finalAttrs.version} on purpose: an anchor that walks from
# `fetchFromGitHub {` breaks on those inner braces, which is exactly why
# the anchor keys off the `tag` attribute instead.
const SRC_ANCHOR = 'tag = "[^"]*";\s*hash = "'

def main [] {
    let sandbox = (mktemp -d)
    let nix_file = ([$sandbox "default.nix"] | path join)
    $NESTED_SRC_FIXTURE | save -f $nix_file
    let multihash_result = (update-multihash {
        file: $nix_file
        hash_steps: [
            { field: "hash", label: "source hash" }
            { field: "npmDepsHash", label: "npmDepsHash" }
        ]
    } "gemini-cli" "9.9.9")

    let anchored_step = { anchor: $SRC_ANCHOR, label: "source hash" }
    let anchored_rewrite = ($NESTED_SRC_FIXTURE | rewrite-hash-step $anchored_step "sha256-new=")

    let results = [
        (check "rewrite-field rewrites a 2-space field"
            (($NESTED_SRC_FIXTURE | rewrite-field "npmDepsHash" "sha256-new=") | str contains 'npmDepsHash = "sha256-new="'))
        (check "rewrite-field rewrites a 4-space field"
            (($FLAT_SRC_FIXTURE | rewrite-field "hash" "sha256-new=") | str contains 'hash = "sha256-new="'))
        (check "rewrite-field leaves a 6-space nested field untouched"
            (($NESTED_SRC_FIXTURE | rewrite-field "hash" "sha256-new=") == $NESTED_SRC_FIXTURE))
        (check "field-matches? finds package-level fields"
            (($NESTED_SRC_FIXTURE | field-matches? "npmDepsHash") and ($FLAT_SRC_FIXTURE | field-matches? "hash")))
        (check "field-matches? rejects nested-only fields"
            (not ($NESTED_SRC_FIXTURE | field-matches? "hash")))
        (check "update-multihash refuses steps it cannot rewrite"
            ($multihash_result == false))
        (check "update-multihash leaves the file untouched on refusal"
            ((open $nix_file) == $NESTED_SRC_FIXTURE))
        (check "anchored step rewrites the nested src hash"
            ($anchored_rewrite | str contains 'hash = "sha256-new=";'))
        (check "anchored step leaves the package-level field untouched"
            ($anchored_rewrite | str contains 'npmDepsHash = "sha256-npmdepshash=";'))
        (check "hash-step-matches? dispatches on step kind"
            (($NESTED_SRC_FIXTURE | hash-step-matches? $anchored_step) and (not ($NESTED_SRC_FIXTURE | hash-step-matches? { field: "hash", label: "source hash" }))))
        (check "anchored rewrite accepts legacy sha256: values"
            (('  hash = "sha256:0abc123";' | rewrite-anchored-hash 'hash = "' "sha256-new=") | str contains 'hash = "sha256-new=";'))
        (check "anchored rewrite accepts sha512 SRI values"
            (('  hash = "sha512-oldhash==";' | rewrite-anchored-hash 'hash = "' "sha512-newhash==") | str contains 'hash = "sha512-newhash==";'))
        (check "require-hash-step passes matching content"
            ($NESTED_SRC_FIXTURE | require-hash-step $anchored_step "default.nix"))
        (check "require-hash-step fails on unmatched steps"
            (not ($NESTED_SRC_FIXTURE | require-hash-step { field: "hash", label: "source hash" } "default.nix")))
    ]

    rm -r $sandbox

    if ($results | all {|r| $r }) {
        print "All tests passed"
    } else {
        exit 1
    }
}
