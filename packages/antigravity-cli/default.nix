{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.14";
  buildId = "1.0.14-6049473256882176";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-FBUHG05PFcBeT9uSVCI1yRQpWrbn9nv8JpH61LmGtsRfsGtbzC/eX5QpqJ78wkbRxEQohJF3CjL4ecKFldt6/w==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-uVCFTl58qI7YWVpHL01lUzEnX53fLp6+OBD4nHTIbTDlCMwIdx6kLg0RL2W/QvVoD0EJ4a7tr8XWHznYj/Zpgg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-uaCMc4wRqIr8M+7+QOXfJsv4SUAp2CY+DVTopdx6bvRRYiji97ethzTQnjfER6sQjZYnb/i2e3168fBLs9nXcA==";
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
