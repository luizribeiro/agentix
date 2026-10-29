{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.10";
  buildId = "1.4.10-5501573669978112";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-IeGIaLY6NVVZGVhvE97fjVkBUbT4GOXuxcyFoX+yJTD33HBf3WJ3ZjczFxI7r8C24Owloz0x8UTGAUEgrmDGqA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-OhTCFpfoY0nOhALgsYicvR06X04stNxDquHEjEBCQMLM/593Xuwnfh91kjSjPsAmZFxj7SKrb26+3lYe2nw4tg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-AYLCOIKxdMbylorYjeQyYmkuw2OpOAMTGRMVUdq0HMaspXPSjSZAlds1fkmIGiERFK/p+XQ4btNyCHYPQBupjA==";
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
