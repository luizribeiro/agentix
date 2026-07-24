#!/usr/bin/env nu

# Integration tests for scripts/update-package.nu. Runs the dispatcher
# against sandbox packages/ trees so no case ever reaches the network:
# each dummy package's update.nu exports a canned `latest-version` and
# an `update-files` with a canned result.
#
# Usage: nu scripts/tests/test-update-package.nu

const DISPATCHER = (path self ../update-package.nu)

def make-package [sandbox: string, name: string, latest: string, succeeds: bool] {
    let pkg_dir = ([$sandbox "packages" $name] | path join)
    mkdir $pkg_dir

    $'{ lib }:

{
  pname = "($name)";
  version = "1.0.0";

  meta = {
    description = "Dummy package for update-package tests";
    mainProgram = "($name)";
  };
}
' | save ([$pkg_dir "default.nix"] | path join)

    $'export def latest-version []: nothing -> string { "($latest)" }

export def update-files [version: string]: nothing -> bool { ($succeeds) }
' | save ([$pkg_dir "update.nu"] | path join)
}

def make-sandbox [packages: table<name: string, latest: string, succeeds: bool>]: nothing -> string {
    let sandbox = (mktemp -d)
    for pkg in $packages {
        make-package $sandbox $pkg.name $pkg.latest $pkg.succeeds
    }
    $"# test\n\n<!-- BEGIN package-table -->\n<!-- END package-table -->\n"
        | save ([$sandbox "README.md"] | path join)
    $sandbox
}

def run-dispatcher [sandbox: string, args: list<string>]: nothing -> record {
    cd $sandbox
    ^nu $DISPATCHER ...$args | complete
}

def check [label: string, result: record, expected_exit: int, needles: list<string>]: nothing -> bool {
    let missing = ($needles | where {|n| not ($result.stdout | str contains $n) })
    let ok = ($result.exit_code == $expected_exit) and ($missing | is-empty)
    if $ok {
        print $"✓ ($label)"
    } else {
        print $"✗ ($label)"
        print $"    expected exit ($expected_exit) and output containing ($needles)"
        print $"    got exit ($result.exit_code), output: ($result.stdout | str trim)"
    }
    $ok
}

def main [] {
    let clean = (make-sandbox [
        { name: "dummy-a",  latest: "1.0.0", succeeds: true }
        { name: "dummy-b",  latest: "1.0.0", succeeds: true }
        { name: "dummy-ok", latest: "2.0.0", succeeds: true }
    ])
    let failing = (make-sandbox [
        { name: "dummy-a",    latest: "1.0.0", succeeds: true }
        { name: "dummy-fail", latest: "2.0.0", succeeds: false }
    ])

    let results = [
        (check "no arguments"
            (run-dispatcher $clean []) 1 ["missing package argument"])
        (check "unknown package"
            (run-dispatcher $clean ["nope"]) 1 ["Unknown package 'nope'"])
        (check "--all combined with a package name"
            (run-dispatcher $clean ["--all" "dummy-a"]) 1 ["not both"])
        (check "single up-to-date package"
            (run-dispatcher $clean ["dummy-a"]) 0 ["updated=false"])
        (check "single successful update"
            (run-dispatcher $clean ["dummy-ok"]) 0 ["updated=true" "current=1.0.0" "latest=2.0.0"])
        (check "batch of up-to-date packages"
            (run-dispatcher $clean ["dummy-a" "dummy-b"]) 0 ["2 up to date"])
        (check "--all covers every discovered package"
            (run-dispatcher $clean ["--all"]) 0 ["1 updated, 2 up to date, 0 failed"])
        (check "failing update exits non-zero"
            (run-dispatcher $failing ["dummy-fail"]) 1 ["Could not update dummy-fail"])
        (check "batch with a failure exits non-zero"
            (run-dispatcher $failing ["dummy-a" "dummy-fail"]) 1 ["1 up to date, 1 failed"])
    ]

    rm -r $clean $failing

    if ($results | all {|r| $r }) {
        print "All tests passed"
    } else {
        exit 1
    }
}
