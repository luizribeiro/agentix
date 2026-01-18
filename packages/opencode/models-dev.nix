{ lib
, stdenvNoCC
, bun
, fetchFromGitHub
}:

let
  pname = "models-dev";
  version = "0-unstable-2026-01-14";
  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "models.dev";
    rev = "db79e08e389c7d10994b5d5b99165c3e124da958";
    hash = "sha256-Z1EcHBDZSz6xUN4S9TSzRTbRLXoRQPuWx+a6myxxDMA=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [ bun ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress \
        --os="*"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-E78Hb4ByMfYL/IZG911dX6XRRKNJ0UbQUWMSv0dclFo=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src node_modules;

  nativeBuildInputs = [ bun ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${node_modules}/. .

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cd packages/web
    bun run ./script/build.ts

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/dist
    cp -R ./dist $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "Comprehensive open-source database of AI model specifications, pricing, and capabilities";
    homepage = "https://github.com/anomalyco/models-dev";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
