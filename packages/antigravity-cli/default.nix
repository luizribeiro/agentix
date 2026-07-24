{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.6";
  buildId = "1.1.6-6535449645285376";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-drgBssUusQbsJQc72l1hoovD/3j3ljFnVkK3Q805/i5QOaFCEdA8q+6IvwNFB4WvWFnR58pHxcUeBnY4m0udRQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-nxNXIjw4v3dRzRaPRhkf6W9e/7vb+e1cq/EnaGXOXQMWO0GKg6mCgsdTorv1NeyXfwue4c87xB/Amj0eYxusTA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-dTtG6TKa7GwKYJ58tb6CgUY/U1BTUBpQKu1aoiU+NTO9cxRIQj1raDsTHsXYdyn7M6jrm2vrJ5Re0NnHqyOXBA==";
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
