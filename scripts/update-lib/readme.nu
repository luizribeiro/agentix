# Update the version cell of a row in the packages table of README.md.
#
# `row_anchor` is a literal prefix that uniquely identifies the row, e.g.
# `'| `gemini-cli` | `gemini` |'`. The third column (version) is rewritten.

export def update-readme-row [package: string, version: string, row_anchor: string] {
    let readme_path = "README.md"
    print $"Updating README.md version for ($package)..."

    let content = open --raw $readme_path
    let updated = (
        $content
        | lines
        | each { |line|
            if ($line | str starts-with $row_anchor) {
                $line | str replace -r '\| ([0-9]+\.[0-9]+\.[0-9]+) \|' $'| ($version) |'
            } else {
                $line
            }
        }
        | str join (char newline)
    )

    $updated | save -f $readme_path
}
