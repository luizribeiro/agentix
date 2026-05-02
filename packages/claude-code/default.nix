{ lib
, stdenv
, fetchurl
, makeWrapper
}:

let
  version = "2.1.126";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-e1p/d4ugb3a28+i1AfRcjFMDnFS9isxsJOy9sYlINmX98pDyCIY76MyJw1HDH0z0x/8jEK30nx/lrrNAvIMNwA==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-D2A9TI62aoQcxxbZzsiOWlfqs+7X/K49qSthkPdCg4B24aQWv2rL0PWTvnvMTbQUTlg6bBL0PjauANdgHs+WjQ==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-iqdERAVEhU2BwEPlHy/S0O3ioKnlFUvlk5xS/G8DXnWok4Niin1HJ+7q4u6ayXWw7JFou3GW3pg34V31ddGhGg==";
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
    hash = "sha256-K3c9xNL2fPQfhNMycZnLudssKRwYd/HBg1aGBi/91KA=";
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
