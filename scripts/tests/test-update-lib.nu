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

# Shaped like codex-cli's default.nix: only per-platform tarballs are
# fetched, so there is no package-level source hash to rewrite.
const PLATFORM_ONLY_FIXTURE = 'let
  version = "0.154.0";
  platformInfo = {
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:0aw3nfbgnc59zv9is640796lh5jzmlmc2mprwxg6hcb0ksj86z72";
    };
  };
in
{
  pname = "codex-cli";
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

    let fod_file = ([$sandbox "fod.nix"] | path join)
    $PLATFORM_ONLY_FIXTURE | save -f $fod_file
    let fod_result = (update-fod {
        file: $fod_file
        npm_name: "@openai/codex"
        platform_suffixes: []
        source_hash: false
    } "0.163.0")

    let pkg_dir = ([$sandbox "packages" "codex-cli"] | path join)
    mkdir $pkg_dir
    $PLATFORM_ONLY_FIXTURE | save -f ([$pkg_dir "default.nix"] | path join)
    let runner_result = do {
        cd $sandbox
        update-files-from-config {
            source: { type: "npm", name: "@openai/codex" }
            strategy: { type: "fod", platform_suffixes: [], source_hash: false }
        } "codex-cli" "0.163.0"
    }

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
        (check "update-fod without source_hash succeeds on platform-only files"
            ($fod_result == true))
        (check "update-fod without source_hash still rewrites the version"
            ((open $fod_file) | str contains '  version = "0.163.0"'))
        (check "update-fod without source_hash leaves platform hashes untouched"
            ((open $fod_file) | str contains 'hash = "sha256:0aw3nfbgnc59zv9is640796lh5jzmlmc2mprwxg6hcb0ksj86z72"'))
        (check "update-files-from-config forwards source_hash to update-fod"
            ($runner_result == true))
    ]

    rm -r $sandbox

    if ($results | all {|r| $r }) {
        print "All tests passed"
    } else {
        exit 1
    }
}
