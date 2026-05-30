{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.3";
  buildId = "1.0.3-6260531212976128";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ssDSGHaum2+vYWSxW1c9duN59kPgQOd9Uo66+l1b2Ik8w8jr2aePr2e9fGdt1L/w8Cjzu7UI5UR2nWHePaa4sQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-9s+JDUlPX9AMaWtNLlQciU1bEP9Qv9n23AK5FThuCLYcVhQPFxFYmPxJ9KpFNFgTkwmPNdtwvpquIN/eO6V4fA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-D20ybvKOV+Rzx4JVgzFGNvoLzaUOJxF/89AZGW0EjXZK8phGkQovI43Iej+QBi4ptSUiMsfVhqhquq6pIWl+Ug==";
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
