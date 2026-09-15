{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.3";
  buildId = "1.2.3-5101874907578368";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-nQtuiRlg3f98Gi1TKgjqslte69HklTQj8aVkwmFk7iK09OJ6FB/jH5WCf1kk4EpK6hBCIwXh3dk3T0v/USTZlg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-7HTcXOIOZGI6TWjnOolX5GjAJr2z0HsVxSkUkDIxM5cMc12YWvg56rBXtSsb/Rsukf9Jq+6+8DL/rm3e2OKnYw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-vasbzdT+p56uZjI5oG6OeWTZkF7G+gcgdmRPdQbHznPPLrhWPrcGA2a9torYFeX8W93zirYh85r/V2qQiZo6xg==";
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
