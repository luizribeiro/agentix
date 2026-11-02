{ lib
, buildNpmPackage
, fetchurl
, nodejs_22
, makeWrapper
}:

buildNpmPackage (finalAttrs: let
  version = "1.5.0";
in {
  pname = "pi";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-W/tmhIpMS4HGN86NITa+AZRbcKrI6FVrCRywIkGzhd8=";
  };

  sourceRoot = "package";

  # Upstream's npm-shrinkwrap.json omits `integrity` for the first-party
  # @earendil-works/* packages, and fetch-npm-deps prefers a shrinkwrap over a
  # lockfile when both are present. See update.nu for how the lockfile is made.
  postPatch = ''
    rm -f npm-shrinkwrap.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-JF73wmGiapTmCkgUbbnaC5RGx/0sasaDK1tTH/1N80Q=";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@earendil-works/pi-coding-agent
    cp -r . $out/lib/node_modules/@earendil-works/pi-coding-agent/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/pi \
      --add-flags "$out/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" \
      --set NODE_PATH "$out/lib/node_modules:$out/lib/node_modules/@earendil-works/pi-coding-agent/node_modules"

    runHook postInstall
  '';

  meta = with lib; {
    description = "pi.dev - A minimal terminal-based coding agent";
    homepage = "https://pi.dev";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
    mainProgram = "pi";
  };
})
