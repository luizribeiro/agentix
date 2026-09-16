{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.4";
  buildId = "1.2.4-6085322963025920";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-39dHFqpnt+MuaXTD5WXf/EBfM7Ec1SMCXmb1iRSp8aHTEZnZZjHQ3m/0AA77ASh1SZnMhpoAMNK7phQs1VP+Lw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-WBHTnsG/lqgu0G3muO4rt/W+jXRCO4xStrl16PDiyExswvoLr5AqrZQsdWZQnDum3bXvB2JgxqY1xGFuauF4lw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-dfnEjKd4MoZC8g6AvE1KlWRupCzhO9Mb8Mil0FAXS9LsTdbNmaS2OTBYbv2ziw3of59WLsMA1SmHZ5uOJ6okvg==";
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
