{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.15";
  buildId = "1.2.15-5434575321694208";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-G3XaFQHuPod/pwgRbzG9iPq8fyXYpLKe95SLlkfXrYVJuY9sI0GHVqOPohCholpSZzkAXqexeOUIR7Z7lnz8fQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-bS4u7aDK1urI6LLfESV9aEIQ+NOEou4BHcatDtrPoz4eycVUWJ9v9u8Gl/TDx3e6RrboRjlxHxczd8wVVMZ0Ng==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-GZ5kGf11Sfopb1HGA1yeAkb57NObZiTEb/mkFvcrC2V5mZxpLJSZ0hip+IdG1g7njQ9ZKzHI+ri+hbDUBTOZHQ==";
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
