{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.7";
  buildId = "1.0.7-5436940900761600";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Cx+MGTTU5eVspGRe7TksWF8sZBaKIY9V+npIu+P1/+s0iMXwbZ3gZgRclkz4oKFzhm2P6G9SeozKgQrUEU7yrA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-W9pSCt5hDFCrR6VMZxli4Osy/M5Ei8LeFOVTt6FaclVGJZG3IdOkDWmVAmG7+3b/JLP4ja6PoAr3J3TDhfw1Ig==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-IgGPSgM6KAbSHpSwn0PCbXnIDOzgwVih6ezUMvcfkdc8QvtDsomBD2LcKjKWbV/d6ZQyYWViAmxQI6ZXp59Ajw==";
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
