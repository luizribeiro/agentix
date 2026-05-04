{ lib
, buildNpmPackage
, fetchurl
, nodejs_22
, makeWrapper
}:

buildNpmPackage (finalAttrs: let
  version = "0.73.0";
in {
  pname = "pi";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-9hTRUh87tkSOQdKW1q9OcUC+ekxa844O65yuabsSdLs=";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-rFmQCjYdRAm+XHPTY2NDA77S4ud+7GwI6nKTHnyX7JU=";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@mariozechner/pi-coding-agent
    cp -r . $out/lib/node_modules/@mariozechner/pi-coding-agent/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/pi \
      --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js" \
      --set NODE_PATH "$out/lib/node_modules:$out/lib/node_modules/@mariozechner/pi-coding-agent/node_modules"

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
