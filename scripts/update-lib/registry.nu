# Latest-version lookups against upstream registries.

export def latest-from-npm [name: string]: nothing -> string {
    http get $"https://registry.npmjs.org/($name)" | get dist-tags.latest
}

# Honors $env.GITHUB_TOKEN to avoid the 60 req/hour anonymous rate limit.
export def latest-from-github [owner: string, repo: string]: nothing -> string {
    let url = $"https://api.github.com/repos/($owner)/($repo)/releases/latest"
    let token = ($env.GITHUB_TOKEN? | default "")
    let response = if ($token | is-empty) {
        http get $url
    } else {
        http get --headers [Authorization $"Bearer ($token)"] $url
    }
    $response | get tag_name | str replace 'v' ''
}
