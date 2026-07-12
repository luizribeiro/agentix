import { readFileSync, writeFileSync, existsSync } from "node:fs";

const EXACT = /^\d+\.\d+\.\d+$/;
const DEP_FIELDS = ["dependencies", "devDependencies", "optionalDependencies"];

const lock = JSON.parse(readFileSync("package-lock.json", "utf8"));
const nodes = lock.packages;

const installedVersion = (consumerPath, dep) => {
  let dir = consumerPath;
  for (;;) {
    const key = (dir ? `${dir}/` : "") + `node_modules/${dep}`;
    if (nodes[key]) return nodes[key].version;
    if (!dir) return null;
    dir = dir.includes("/") ? dir.slice(0, dir.lastIndexOf("/")) : "";
  }
};

const alignDeps = (consumerPath, deps) => {
  let changed = false;
  for (const field of DEP_FIELDS) {
    const edges = deps[field];
    if (!edges) continue;
    for (const [dep, spec] of Object.entries(edges)) {
      if (!EXACT.test(spec)) continue;
      const installed = installedVersion(consumerPath, dep);
      if (installed && installed !== spec) {
        edges[dep] = installed;
        changed = true;
      }
    }
  }
  return changed;
};

let lockChanged = false;
for (const [path, node] of Object.entries(nodes)) {
  if (alignDeps(path, node)) lockChanged = true;
}
if (lockChanged) {
  writeFileSync("package-lock.json", JSON.stringify(lock, null, 2) + "\n");
}

for (const path of Object.keys(nodes)) {
  const file = (path ? `${path}/` : "") + "package.json";
  if (!existsSync(file)) continue;
  const pkg = JSON.parse(readFileSync(file, "utf8"));
  if (alignDeps(path, pkg)) {
    writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
  }
}
