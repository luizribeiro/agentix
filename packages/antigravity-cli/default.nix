{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.17";
  buildId = "1.1.17-5084709148033024";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-7aF+nzZJ3xK81hTiJpg5Is1eTCKpFT6fml7MVVet3NoPAxR9uKLGwZ2uuOHcgGKpobz4YoQxXCsarnPy2CNrHg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-XGBHoZ6AAl6nzsyBUvsmOn8U6AWR7nW98coQGRzAzRY5tbXr3OTRydQ7FL0kRvA4pFeCFpRXn0OStsqXNlEpNg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-rYcVOPyLvQz5bhG4XjiNrd5c0CFkwpIc980wZG40PJCmPvUiT2QgYSrW+R/gbyYOMy4weWgILzofVOU5M76Efw==";
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
