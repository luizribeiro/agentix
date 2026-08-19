{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.15";
  buildId = "1.1.15-5350383476932608";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-1H1mGOSVgxEoDu1QXDDG20R3f5tb71ORgoPB6HTLxjUoxxDr63pHcBCTK50VY94yp0B69msk5qU9Y8RocM8Ofg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-fWAgyv8uBqXd8lU/LZ1bQo477MaXJ9EQMvEOQGCbk420KFeMzVxyaUurXk2kg96a0xIVeMwXKt8XSqUmPOUdzA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-JXEDHe2AemJPrVFmv7fuLrDJeGJID8Qj2mc/3iAltxo1JA0hPs5qQq1E0hWVn6BQpxdQx281i+/dJF9ZM8ShBA==";
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
