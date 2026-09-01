{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

let
  version = "0.152.1";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:04mbwavwx8j0h76n14ph9s0d32lh7ggb9k61hn7pf92788dgz057";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:1kb50p8l6ldlda8vccyn88v9l0knfb1jcq2378h5wyhih279gm0f";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:0ra748vahhx6nqhawffm54xmyw3rygc0281iypj85w0112h3mi94";
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

  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";
    hash = "sha256-PbeqsOCEVMkIqHTFYfdak9OzBPLaIZVycs17c/9FGVs=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs_22 ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@openai/codex
    cp -r . $out/lib/node_modules/@openai/codex

    mkdir -p $out/lib/node_modules/@openai/codex-${info.suffix}
    tar -xzf ${platformPkg} -C $out/lib/node_modules/@openai/codex-${info.suffix} --strip-components=1

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/codex \
      --add-flags "$out/lib/node_modules/@openai/codex/bin/codex.js" \
      --set CODEX_MANAGED_BY_NPM 1 \
      --set NODE_PATH "$out/lib/node_modules"

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenAI Codex CLI tool";
    homepage = "https://github.com/openai/openai-codex";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "codex";
  };
}
