{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.0";
  buildId = "1.2.0-5210873191596032";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-fKTJ0EStx2oaew1ec/qLPcDVbp6EF/cqdH6b+f+Xg/eldyLGAsL7ubW/WWfktVaOT2InBIDfSZ+iWrlxyMKohg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-0ZCyWgTtKgOwWHg4R2SUrlnQ0yTuY3MmPKvlhDUsJU+QUfNonHmsSt2IF/9us0sRaUrNdwAsVekb0dKLbf2uIg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-WtcvuoyOkVxZxVBdyZEWBYNSuOun8UHX7SICVniLraMN+LWvZcDZMf8Qu8ZhwPX+g5McWAcf4wY6gJu+2n9Z+Q==";
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
