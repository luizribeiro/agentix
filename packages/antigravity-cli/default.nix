{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.11";
  buildId = "1.0.11-6118976565149696";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-IW41qkBvKPZE8g1chMMFSZWtOYBRnLM14DvAFFKeoMN65Bbh1lT81z067FtF/nMdNMAqDIrsQeZmNHIRm47k2g==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-AdTcBfCrp760WYIbRvdejd7Y/cSXARZGjT4UEIehOKiXk14F74v1ANxO3rudUO8Xx4KtrkYJf3fMOXHvVW5Rtw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-e48sq2qXPJeosf4aC/FGoKPRw4cOHGEh3lSaD9sn1i9GWYBTLw+6mi69PP1Ba9fu1zdziwtmGzB+aNYgrV9bxg==";
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
