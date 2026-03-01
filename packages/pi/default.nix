{ lib
, stdenvNoCC
, fetchurl
, nodejs_22
, cacert
, makeWrapper
}:

let
  version = "0.55.1";
  pname = "pi";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-+gUj3BPFAmxqkeNcYLg1J1iXAjEdWpByqX4Ixyc4NmE=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version;

    dontUnpack = true;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [ nodejs_22 cacert ];

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

      ${nodejs_22}/bin/npm install -g --prefix $TMPDIR/npm-global \
        --cache $TMPDIR/npm-cache \
        --no-update-notifier \
        --no-fund \
        --no-audit \
        ${src}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/node_modules
      cp -r $TMPDIR/npm-global/lib/node_modules/@mariozechner $out/lib/node_modules/

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = {
      "aarch64-darwin" = "sha256-djI4nH91SQkNl56FcDN4B9JVfWEZWAjJ/r/wjAmueYA=";
      "aarch64-linux" = "sha256-Q6QU0TFLk8hdCdIqVeqGgYoYJZClhmJ8+/pLUrRqImQ=";
      "x86_64-linux" = "sha256-cryxDJbXnU3lRp3psWHBH1/NVU4G/i7pcBEGNeFlB3w=";
    }.${stdenvNoCC.system};
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules
    cp -r ${node_modules}/lib/node_modules/@mariozechner $out/lib/node_modules/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/pi \
      --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js" \
      --set NODE_PATH "$out/lib/node_modules"

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
}
