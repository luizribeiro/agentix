{ lib
, stdenvNoCC
, fetchurl
, nodejs_22
, cacert
, makeWrapper
, qemu
}:

let
  version = "0.3.0";
  pname = "gondolin";

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/gondolin/-/gondolin-${version}.tgz";
    hash = "sha256-z/TAXYFzA35lC4xFXpVDV5/mrhqgzoZskzeR3Jl8cR8=";
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
      cp -r $TMPDIR/npm-global/lib/node_modules/@earendil-works $out/lib/node_modules/

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = {
      "aarch64-darwin" = "sha256-h77F4yEXF2rK4dECHMI7T+5+/jTdUUfAQPWofQQ7omc=";
      "x86_64-linux" = "sha256-h77F4yEXF2rK4dECHMI7T+5+/jTdUUfAQPWofQQ7omc=";
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
    cp -r ${node_modules}/lib/node_modules/@earendil-works $out/lib/node_modules/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/gondolin \
      --add-flags "$out/lib/node_modules/@earendil-works/gondolin/dist/bin/gondolin.js" \
      --set NODE_PATH "$out/lib/node_modules" \
      --prefix PATH : ${lib.makeBinPath [ qemu ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local Linux micro-VM sandbox with programmable network and filesystem";
    homepage = "https://github.com/earendil-works/gondolin";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" "x86_64-linux" ];
    mainProgram = "gondolin";
  };
}
