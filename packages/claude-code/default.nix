{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, nodejs
}:

let
  version = "2.1.247";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-PgInuhsq1LONloSE6puAPzQUakRDDkX8fYPz+k7CCJK8uvfsxtSwA19T1l3ebVuZauPcss+E4abk+WFwGlY3Cg==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-ZHjg+YRpBDKmTzIWtVF7ofABjwz387bCjDCUyO89ttuOwlUvh1zmCVwTlL6BdJO/v9uCTbQOrM7GUIDqzmPAoA==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-oz5zSpSHY3WBaajo70L61YVM0efGxhoguOhz2DjbVy/Q6EvXoDaAj6813IzIHHsRugLYQ36D1B32GDSL63mz6Q==";
    };
  };

  info = platformInfo.${stdenv.hostPlatform.system};

  nativePkg = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${info.suffix}/-/claude-code-${info.suffix}-${version}.tgz";
    hash = info.hash;
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-xj/37gH7yC93tubGxycLVSLhmmFkg0SZ45MANN9ZZxA=";
  };

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ nodejs ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
    cp -r . $out/lib/node_modules/@anthropic-ai/claude-code

    mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code-${info.suffix}
    tar -xzf ${nativePkg} \
      -C $out/lib/node_modules/@anthropic-ai/claude-code-${info.suffix} \
      --strip-components=1

    mkdir -p $out/bin
    makeWrapper $out/lib/node_modules/@anthropic-ai/claude-code-${info.suffix}/claude $out/bin/claude \
      --set CLAUDE_CODE_INSTALLED_VIA_NPM_WRAPPER "1" \
      --set CLAUDE_CLI_DISABLE_UPDATE_CHECK "1" \
      --set SKIP_CLAUDE_UPDATE_CHECK "1" \
      --set DISABLE_AUTOUPDATER "1" \
      --set DISABLE_INSTALLATION_CHECKS "1"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code CLI - Anthropic's official CLI for Claude";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = builtins.attrNames platformInfo;
    mainProgram = "claude";
  };
}
