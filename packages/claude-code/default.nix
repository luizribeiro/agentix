{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, nodejs
}:

let
  version = "2.1.146";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-1xRFcJRazPa/UU8IalR+2rP9Glwylc3OFlENm1+/PmdIa604s5B1wNygkvcqhVmE8rJO65uyJXjfB3CKtq0PQA==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-OL1laix9AFc/n6/vVynQQtUsMQrHJXtpQs7m1sp3na7gRqxdr9TEUSQ7ZcoCD6uuFdXZnVHf6+tI14Og/D2RLQ==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-I20fmJwaT46rd5SdI117rX2ktFYA74L+ldQWmGGle3Dn4MuPQBGC+pZBcp8dlR4ydkC4HWyvyTNECu+BHpW6iQ==";
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
    hash = "sha256-wbHbQIgYOyP6/0Weid3oMxZnFEr3ho8CiEI7/8RVlGk=";
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
