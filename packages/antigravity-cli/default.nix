{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.12";
  buildId = "1.0.12-6156052174077952";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-bBZZJiyzL3s7IAbxGzF+ChMBxiTrbJiDPLy+X188oICoDknj96tNykUoiQM1lQoj0uZZOVFbpxUdaUVcu3YkEg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-mG4c8kA64uIQNKtS4H3OYEbxVtXVbCeGsg8mAnqNYPlpcUT8uS2BFiGSH8+US4+bwuD1wAkwXFDh6+xiUqnrOw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-Uan7jzc2vV/PsyueQJNt66eIN5awyQQfkQgSnFFo9jkqX8Lsyt72/4ryo14q0SABFmetqB4Oal2NV06FFZ0OXg==";
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
