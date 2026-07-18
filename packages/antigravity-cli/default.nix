{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.4";
  buildId = "1.1.4-6277569641840640";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Aq3QAk37ZLlBFb05220hwjt9nYsQ6EH2zmXxZgb/8uWiSRnFAdXCGJS81Fnt3gen9jzmHUe4Iud2Mhb0cR+6HQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-oIih8jHYVltmc87Nhlb8NQTknInpxrjEEWk3tf5wacjc+6eLuyvFwP+Oh7pk/iG2PbcAHjpXlFBJJ9rZ6J2pcw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-jTxGQwOyNbbywtRB7KB7DBzDXvpo964WsWelotSTc5A+/faGs+QQY0JPDPDFtdXrBW95RNreer8bjrIly4xDjA==";
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
