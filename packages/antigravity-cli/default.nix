{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.16";
  buildId = "1.2.16-5594158052802560";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-g0pi3Jcs/fCc2wAce6ebtbya5azbqL2cTSk5BFt24Zyb227qxY7Yih3qoWcPyTNe7hhIL+LzJgPngiTelXOw/g==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-wx8JJl1Pau98A7UQVmGumPmoNlxsgSxorcxKXh+Lj5bAX9LkQIpS9eh+G1Yaw1D0/6etQaGRiTvno3MMz51lUw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-0X2ARHNtMeJM58TLO3X67zzlEC7KrTGu+VeFwPPBP6BhXXsR+kEetzuEhImt+dQRF4RG8xSOMDU6IEjNPnMZcQ==";
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
