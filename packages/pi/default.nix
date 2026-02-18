{ lib
, stdenvNoCC
, fetchurl
, nodejs_22
, cacert
, makeWrapper
}:

let
  version = "0.53.0";
  pname = "pi";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-isNl7f8bvKTgMr8AJMM0VT/xLiRc+AY3hmA08Ruj9wQ=";
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
      "aarch64-darwin" = "sha256-Lyq33JM30l+/rx1XIDxLWXZ86WziY+xv6yEv/XiPOgk=";
      "aarch64-linux" = "sha256-99tHdcCSJmWcKuF1OvEu2k6XbplRUi15EZA8Vk/G4P8=";
      "x86_64-linux" = "sha256-wkYnaPsWQqIFFiz/evx773H5jzQs+iScF2RxjY1m+JI=";
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
