{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.2";
  buildId = "1.1.2-5174998495789056";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Ix8Ql3qvgV5t6HFTXJn8egKW+HMvP4jOVbz1fs0nu9zN86FjQA9qpsdqZtRx0+DB9AfsYLWsebjqqdtBI97f/Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-t6G2BqYcl8yxWSpk1omtD9DtRJFZLzR0rfbPDmGT0js5DhMI+Jod1OeDBq6rE/4I3LGkok2j5Fg8O9aEXVLEVg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-3y0UfO5PbYVjDJi8vAlzadR4l7mqyXy7YCex4RySDDao3if0nN4Fw7vtCpuaHfwlQuW4yTYGk1rEr36zy62Isw==";
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
