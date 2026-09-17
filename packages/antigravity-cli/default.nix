{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.5";
  buildId = "1.2.5-4931130160447488";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-W75MQMMcixZl4HPEtqi2Wi1gNApafWmMECMZIbZ1MYQBJtaMeivt2ZTLY7JsoCaqEFzOQTvJrqqQV8/GzwrzRQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-H4mXN1nslgiYNwi+mF1xWvFmn1CkPvchpzibmo3ngUEzPhi+3+99FdAHPL5Na4mEyGsj2NBzzCjdKSkKeB9LZQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-4RyZACSz8lP91v/VUuEXR4yzILv1vy/2eiGPracYyO7rrXzZFraR45o7IGoJvHVNF3MZsALBqqVGq05e5GM78A==";
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
