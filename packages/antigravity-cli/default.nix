{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.2";
  buildId = "1.2.2-6061403484848128";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ijte3qUeEHp0QTzqXu0cWwLe3pRbohx2JbfIb0d8LIrEI1gd4O2E/y+Xw79oGMH8JMqEz5p2wvsCpQ6J2KDSmg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-dDQs8qeLNEOS5XO2OKZIpq0fjod/SUuW4g+cK3kVjVxCPECy3PeIcDNiuwqRUPCccH/eWZ11V84BwSIIgCpjyw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-oWRaMPNrdnx1NML2pT6Zqb+t6ZMmfvzKcV96RdeX1H1lYd94fp1KUaO9/JvoVdSdI/o/S5GyxmH9FzFAUINgSA==";
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
