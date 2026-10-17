{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.1";
  buildId = "1.4.1-6385551759245312";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-pDlYT0UBe7a0+0Wzfb6slgt+mfsujH1gHLy1k4VMlO1H+C8bGT0S2w+P618TraPL8nXlSRvm6LCp9uHWeZtVsQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-4pGtuiDevQ8wkpelj6Y1WyeMarwhz8suMkV4PE83CLrBSnY5YAlz4tA8ylpjuEL2Jj6Z/+Vj90YGYwBP7gezjA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-UeqTEvN4liOZ+qZzsbL+QES4AeZiUFxcPgXWlP2EmKTGtl8PHDImKdK1voJO8UTI4ZaxJT8Tl6QrloSVFPYLPQ==";
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
