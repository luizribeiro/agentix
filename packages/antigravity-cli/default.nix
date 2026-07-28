{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.8";
  buildId = "1.1.8-5636713813508096";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-S8Jk59xnDSOLYqv3D3LzsN1O5m8VyWsWD6LTpt4OAvbLllhhM3c1/X/PoiFUnjTuTlj50RMrRPL64LQggWhmSQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-2kL+xwCAX+slw3M5357TohKerZO+PDJKRo7R9TbBFY62uiKOw+42+fIRyw/lbp/gan/a0DTVnDX5QOwnCzE4QA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-T5RdKM4EzRFYwQfSOPiB3X763VkbeTp2jUCvWCQCh24cML9QNUQIEITLa1Wbd5ZVPuaszSg3a0Xh3oS0UYvZ4w==";
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
