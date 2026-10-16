{ lib
, stdenv
, fetchurl
, makeWrapper
}:

let
  version = "0.163.0";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:0c9wrpx28nbinjnfhn59cxy00zf5km5ba828qgbab1r3wx6gz4qi";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:156y51snpbimxia7v01jnx0418sz27m9p6mmg06r8xdr71vwkvrh";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:08imfs24nf5db06n68kgnwazdvppgxby418dysh26777dm6pqvnw";
    };
  };

  info = platformInfo.${stdenv.hostPlatform.system};

  platformPkg = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${info.suffix}.tgz";
    hash = info.hash;
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = platformPkg;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install the native binary directly instead of going through the npm
    # JS shim. The shim sets CODEX_MANAGED_BY_NPM + CODEX_MANAGED_PACKAGE_ROOT,
    # which makes codex treat this as an npm install and show the
    # "Update available!" prompt on startup. Running the vendored binary
    # directly (from a path codex does not recognize as npm/brew/standalone)
    # makes install detection fall through to "Other", which suppresses the
    # update prompt entirely.
    mkdir -p $out/lib/node_modules/@openai/codex-${info.suffix}
    tar -xzf ${platformPkg} -C $out/lib/node_modules/@openai/codex-${info.suffix} --strip-components=1

    # The platform tarball ships exactly one native binary at
    # vendor/<rust-triple>/bin/codex. Discover it instead of hardcoding the
    # triple so version bumps (or target renames) keep working.
    vendor_root=$out/lib/node_modules/@openai/codex-${info.suffix}/vendor
    vendor_bins=$(find "$vendor_root" -maxdepth 3 -type f -name codex -path '*/bin/codex')
    if [ "$(printf '%s\n' "$vendor_bins" | wc -l)" -ne 1 ]; then
      echo "error: expected exactly one vendor binary under $vendor_root, got: $vendor_bins" >&2
      exit 1
    fi

    mkdir -p $out/bin
    makeWrapper $vendor_bins $out/bin/codex

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenAI Codex CLI tool";
    homepage = "https://github.com/openai/codex";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "codex";
  };
}
