{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.13";
  buildId = "1.0.13-5758107482193920";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-JmPgd7s9orTwTLleFPbcwM3ZX8EfGbDE9hQeBG7IEPiZCt54X4ss/5OK1vw74NzXou38Ki5VVMbQ+fpRalm5mg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-+L4IjOuQ53UDsEA564ZX8f+sKbqzf5BYwlh/rzZBBZAOe3L+kxF0TIP7Gfb58LIDa2O8Acej//emq/6cAhZKbw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-FnGOpYvRYDbncIBRTU7EueN6JVAymDZEANm5Jh6vuyi7NjEkecn9VuSogC5vmJrnOj8lw1Xf1FC0SZMZukjh+g==";
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
