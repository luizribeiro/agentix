{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

let
  version = "0.144.6";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:0jzrjbf79mhy0v35gkf1qx87x4v9pdlskr6rp52q61fjijjmh7b7";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:0s18gld0ipxdhr3bhkshfjddnb1lv251qp5cjv66y3n1x2r2wxdn";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:001qf45r4qspxbymnxjf6nq29xnhwphb4w0n36adywzj6cdv1w0r";
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
    hash = "sha256-d56rJaqEc1g7PR1vkxagq40GQ/39C/74DOdsyM+F5AE=";
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
