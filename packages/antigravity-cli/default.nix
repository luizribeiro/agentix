{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.27";
  buildId = "1.1.27-5211191891591168";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-zWJ/eY4Fn4Soi/4h295UzFJi4tk9GUPxIOtLOGgj9KH3xKV9TQ+HZVdwm2BhpMAvH8ExV/AEfF328wCvpHHkEQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-eT1LnqLAjZp+ULr6As/IwZQkvWDW6D+RQI1F+cbUznml1Xb+3lvvFk2COr+E+BNZoUtMpmWVLEewp8/XQ7tpwA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-7UX2kweFqktC8U4HrOHJ2RqU+3bnYPVKy9fT05UeH5V/1Fag2uKjEk3Zo7aJv3r7fJMDo+S6lQN/wQBjQk2b+Q==";
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
