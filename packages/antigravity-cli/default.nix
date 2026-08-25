{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.20";
  buildId = "1.1.20-5830032204103680";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-pjlhaOn8fm4wu7/syr4rSLMAip3BbWRWReNUtzlIyKLz1PK47koAdB5LeWCu63ZiKcBaNPgFzsmHzBfM/fTy1Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-bNx/yQViukDIvwZY8w7eAW5qzQMIN3m+jVTUv2PdmYADk+M8AK3flD9sK3m02s78b7SpY7KwL2zmNjXvVKQoaA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-cQM22VZTsIqsTh1ANAHEvdlrjryde0FHU9nYPKEDZiT++aSUHtpxCvxbxBbR/3BU2TesFMll9a0o0o4F5GIQkw==";
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
