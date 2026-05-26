{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

let
  version = "0.134.0";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:0z4b1n5n4zqh5ibn90g6lwicxpcc1yn1h79xs1gigf6z5havvj42";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:1bhz3jwg81jyr4j3h210i867blikw63cqi9i9lkg9j15fkwr3k88";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:1kh2zybx0g2j0b45l85nw3qlsbdhyhpzmpqb34kphnpxca8y6iks";
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
    hash = "sha256-BpCxsVISe2WPot7fj3NCJK5Ob8kg193ILEsa7j8ZP5M=";
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
