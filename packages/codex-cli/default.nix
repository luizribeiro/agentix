{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

let
  version = "0.135.0";
  pname = "codex-cli";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha256:1n8vccv1w5cwvl0hbrr2iwf31sm5wrig34wy2lwgvgd1q7wa65d7";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha256:1gybmb5l5849qf47l50g1v36i6wlj5khk4d3pf852jfk9sjh2nq1";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha256:0wfsfn6gxw49qq8px8dc95i71kvix6kkcd4rx4f98jiyv9247vik";
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
    hash = "sha256-WK0X6witZFyWer/KojO+ORoL2kMvmzybz0xsZtC4+6c=";
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
