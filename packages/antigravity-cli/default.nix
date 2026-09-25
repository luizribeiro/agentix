{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.11";
  buildId = "1.2.11-6016716732497920";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-bZwfKjDq9BaG3+QOWmRMnTfBcAGb5ciRE7N0X1/mzfVfHFxeIwDF55dSn4eLaXCrRyWjjNfs1qslDl+61Cz3mw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-yhLCYjQ/KaK4dCPR/x5CRJiek243/h+OVgVrD5HNAvk/EzMhIpzjXIbC2EuXfpGZN6P9lDDP12mhbWsD7eJQgQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-T9T44ZYOAAt4A9ojZcZKczZ38e2A/twcNEMxl48SkXHdHRKOhSVaTy8NOILPCXs4l8wnBLT69NNmn348acwwEg==";
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
