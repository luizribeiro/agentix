{ lib
, stdenv
, fetchurl
, nodejs_22
, cacert
, bash
, makeWrapper
}:

let
  version = "2.1.22";
  pname = "claude-code";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-OqvLiwB5TwZaxDvyN/+/+eueBdWNaYxd81cd5AZK/mA=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs_22 cacert bash ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export npm_config_offline=true

    ${nodejs_22}/bin/npm install -g --prefix $TMPDIR/npm-global \
      --cache $TMPDIR/npm-cache \
      --no-update-notifier \
      --no-fund \
      --no-audit \
      $src

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
    cp -r $TMPDIR/npm-global/lib/node_modules/@anthropic-ai/claude-code/* \
      $out/lib/node_modules/@anthropic-ai/claude-code/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/claude \
      --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
      --set NODE_PATH "$out/lib/node_modules" \
      --set CLAUDE_CLI_DISABLE_UPDATE_CHECK "1" \
      --set SKIP_CLAUDE_UPDATE_CHECK "1" \
      --set DISABLE_AUTOUPDATER "1"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code CLI - Anthropic's official CLI for Claude";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "claude";
  };
}
