{ lib
, stdenv
, fetchurl
, makeWrapper
}:

let
  version = "2.1.122";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-+DC98VI72gZeuSz6VgEc+aAe5RlQGy4gdylf3moyypYPOGzY2eX099pXggdK1sAlFiHQ5xRXCq6QfBnw4/RvZQ==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-i6nqfRnvW0IaCTJSHADxX23ykQTlYsmHRja72W92HhjyG8fudaSH2f1XM/zSbaSOp5s33mZAZ3js5coiH6Ksdw==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-b+ricBXcR7iiEmzelRcRjMGJgpazkvlJzcezFUK41kcJ6HKCPCHVCvGh/4yhoK74PACFA74oSWCp1PK68o0boQ==";
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
    hash = "sha256-CBAe+qYuDRxt50S/V6HrpzWbNFZWZ+3zvxzYWybLMsc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

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
