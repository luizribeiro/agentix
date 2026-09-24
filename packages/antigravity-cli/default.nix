{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.10";
  buildId = "1.2.10-4751581200121856";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-D+OVlo2kW500pLghCmvJnOPByXfIqMQAoxgTEDsiGY2k0OAtGDR58KEbL3H8Ig15OUJj8H0yb0+4FhoVad+xnQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-4ZrvWZqvR6kiXnLyzUINX5fW3ZdOaYaFlQVXyiOovaY+/+ZmdzF4yCkSuY6cGX2imCm5LncetvZsgiNvF4ZP7g==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-EF/uiYlFbkzM1ES9NKcpTDMV/I4709lAIukAU1Mr4CqEN1VG2nh1jW3PL0lVx9MzzL1M1vi4bBjkdmdJPTUXnw==";
    };
  };

  info = platformInfo.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${buildId}/${info.urlPath}";
    hash = info.hash;
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin antigravity
    mv $out/bin/antigravity $out/bin/agy
    chmod +x $out/bin/agy
    runHook postInstall
  '';

  meta = with lib; {
    description = "Google's Antigravity CLI - terminal-based AI coding agent";
    homepage = "https://antigravity.google/product/antigravity-cli";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = builtins.attrNames platformInfo;
    mainProgram = "agy";
  };
}
