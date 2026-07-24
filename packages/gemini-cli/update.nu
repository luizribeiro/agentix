export const CONFIG = {
    source: { type: "npm", name: "@google/gemini-cli" }
    strategy: {
        type: "multihash"
        hash_steps: [
            # The src hash nests inside applyPatches → fetchFromGitHub,
            # below the package-level depth that field steps rewrite.
            { anchor: 'tag = "[^"]*";\s*hash = "', label: "source hash" }
            { field: "npmDepsHash", label: "npmDepsHash" }
        ]
    }
}
