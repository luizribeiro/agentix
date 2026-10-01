{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, nodejs
}:

let
  version = "2.1.287";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-ZQLmkEpiWd8sxUYRpQr1yZ39DyVBhrl8MUtbxe33E+z4jFPtUy+CrJXmeRRyyM+FEfvGe/2ab+E59GiSKkprRw==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-Q31ekN28viVjgfDuZKXUR5vxIBgUYoLGe+cRmjx/f01omqFDMi6IrgmcK5pWMnRbu/cjsTA/zO+bVES5oY3XUg==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-MU3ReK1kjstDmjEOzhFZaphh2AVUKnPaik6lOV0WLs3/mOM7mE/mqkdcQ/Sv0KwHH5MnOhSkIjCEl0/8tr+vRg==";
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
    hash = "sha256-uCkXkBfHOsvECEt2TKOozZ0PNVTsIQdRmicsje2XXvs=";
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
