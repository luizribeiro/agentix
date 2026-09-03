{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.25";
  buildId = "1.1.25-6680093607723008";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-FzqTyr5hzDVSPPmOIcucZ3HuoniK29TOSkzDMdpugXnZ+lH/aqX+GIg5V2fvtJ/Zhj4STj4eYqnYRf/jAdaqCw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-xa9tHPwvrz0YOzSXxWy0lRBnu1boodHlpPCBh1qsKwc72X0OuUWLdy8t25NCIjcpNfSK4seJPXAT2XWv11FubA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-RQ1UmqMVvMNjuVv8WUGYJidOkA0UzHAevyCSLAYe/gTFacE2ZF3f/vG0EeBaTC5FpuhAkwC9iwwHq8sPaSVIPA==";
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
