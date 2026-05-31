export const CONFIG = {
    source: { type: "npm", name: "@google/gemini-cli" }
    strategy: {
        type: "multihash"
        hash_steps: [
            { field: "hash",        label: "source hash" }
            { field: "npmDepsHash", label: "npmDepsHash" }
        ]
    }
}
