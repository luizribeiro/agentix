{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.17";
  buildId = "1.2.17-6683332533157888";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-kpZwOzt5p9qf+D/zsTh2JjnoUMcRhrYr619ZEKezeZ2V2F7DAyDVXUyY2SxeZcevdUQ81R4yRp3Rwr5e6Cns/Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-0OvmEvfPwhyN6eenpilksiRdid21cNXifoPmGizHbLOOgLbrO91xvvaD66AnxKl9zOTO2B9H+Cd2MjTQzT7Fkg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ojFvWwLtjjVMkilSX3oyOcHiSfM6HQRChnxoo5skU2VOjQxIw2v5eyo/zvSvwHp/ee6iqJULVxCruHd9Gj03Vg==";
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
