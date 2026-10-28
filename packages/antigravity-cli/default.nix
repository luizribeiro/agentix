{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.9";
  buildId = "1.4.9-4962164969177088";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-19g2NLDCNmWe5TD0SOmqHF3ACgEGMe3XK/EakgAGiSsxm+flHI3vriJvIEZgVE5NkVu15zPxzrUMBl9MvkXT0A==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-lqJZt0da5wpbAC6oqDuAS7qbatIXGvDNCDmzlZ2eYEa6NuGBvC1Vl1Iq7OqswGAjVkxGIy/blY8m+MciZ9nw/Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-pwPRDqltINNcKragVs4HrBlvrCFc3xrDqHUKUZ+kLDrBvErId2yYyU4KgWtrN76vDl2Y0w7tPmCpDRismgYBMA==";
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
