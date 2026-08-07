{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.11";
  buildId = "1.1.11-4956531888881664";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ikEOIDUKXSJVJv3kMWijdCYl2tMPQ9JUQj342Uektvh56tEmgBpSfj/yVcUI7S1e3GNSzvtIioSciIXAiVzSHw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-MtZFKc8DWrl5A1IGndDfRSXXySC0KHLeF3XmVFXnf9mDs3pt7oGmNFsGDJjV81Bym7XirogbvagPRrdIevRYjQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+xrKzb3mBqYKgAK23AqMmAC7hK7zrdBp+EP2/6Pvqv5KUvzkQFBcbxauvWsSV8zl7PrsLbqyFzLGJZQ0IjGM2w==";
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
