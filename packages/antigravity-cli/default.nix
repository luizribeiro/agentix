{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.7";
  buildId = "1.2.7-6731160148115456";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-4mAyzkIJhaGOcgtuwcCdg2Cu2FHT4zRRSMmgUreRiYmlK2LdLI20U1meo0G4spcgc3hG/9N92caLa8bs5KBZlA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/sdp1hHEr98K5y04vbJlLI4sjnHk9t6XonuA3aPFBCkWDZ4Dd2o2pZuIV8IOdng8SknLD+uLL1w7+SWwzAO7dw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-05+Tn/yAd2v9LcENt7mhobWGUPCBFfohBlwR0QiCxxIQ82jC5gYPJpZtGjPWst0rwZv9ZBBiMFr2VGxR1JRRGg==";
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
