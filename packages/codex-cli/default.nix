{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

let
  version = "0.150.1";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:11f814v67ixyvpk838c6p2vh4wlgvs1lg9r256ny48ksimdql075";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:19n04x4m4wwwm1al1q7fdzznffcd3i020lhf6pcz4p1l4kq7ra1m";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:1d4z05ibzrscny3kg13fhl37ycx6vj1amzhzs2z6vpf0yjn7fmm0";
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
    hash = "sha256-Yca8914VldGrg5j4Qk4ZHZIq7LlDANbZFTNSei9a6Sc=";
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
