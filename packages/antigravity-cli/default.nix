{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.5.1";
  buildId = "1.5.1-4523430503120896";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-B4OZs5LDv85wvF2fsaRHpLCiomvUDDYUj0lEAouPIeNYiQ1bm+3N5pKWZ3sdosAmtOKDrpGII0KcE7kd3LkTzg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-9wQGZU69lm8hFCQzglni040JnEhzTpAdwGl1Bj5aATfVW265Nmt1mDxpCLvCCukqJhdla7GR2O1v5CnWVLyk9Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-/fikY+W/Ts2KAbaKU+AG564CVueuNRo545xm4E4nXG0ItLk/QjzFctI0hx97+FLEUj4BcVak756n3qGq/7Cixg==";
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
