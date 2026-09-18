{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.6";
  buildId = "1.2.6-5912685477494784";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-pcceI7stMtBWkg95wcI75Gk+7H2BUl6TRV0nQDGiv/gsI4uRfhGYyjaXo1xxUijJvSPAZ7QFF79RG2KZr4UgwQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Xic4ttiLEGwpXY49qpajhuVFZl7Fj67ZTVl9KgvCfhac8fkTr4FILaxeCR1uMTn8s8MsYHmLX7q3UT2CMtz3hw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-aFssJfA2p69Ts8zKKsao0SALBwvFei4F+kV0J2xTjs/xn3Y8qXwjLWL8JCL+mNh2DFA/wxvUmp16LtPsEbupAg==";
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
