{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, nodejs
}:

let
  version = "2.1.210";
  pname = "claude-code";

  platformInfo = {
    "aarch64-darwin" = {
      suffix = "darwin-arm64";
      hash = "sha512-Bah0gEfrgKGzZWHieE37+MZNKlCDZ/OSGbD5PLecsJP0ulNoFJoGojWQGs4+fWjcO+LFVIBFJenLqaS1whMJxw==";
    };
    "x86_64-linux" = {
      suffix = "linux-x64";
      hash = "sha512-E1vqxgSheADujZtBdz4UsigHjjulesv7FlYC19Jb/5Sq/csT8zlfKpJhST+LNovP4fU9TkK/urq3pE9c7PaDLw==";
    };
    "aarch64-linux" = {
      suffix = "linux-arm64";
      hash = "sha512-eU6EVzxfey1ceW3qx7zrwWpoh6RnqUbLAFKK//IAqe2RWS3YkO8ABh7rgdWcGUADLAQ5YjTnGrX6VnFufJbZdw==";
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
    hash = "sha256-ohjsDzN9FFMt86uDZvSWTcmbLnRTIljgvMigXQkyz+4=";
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
