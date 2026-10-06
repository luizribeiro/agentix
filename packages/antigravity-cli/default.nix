{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.0";
  buildId = "1.3.0-6233328509124608";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-/crWhjsHqyirUjRRsXtnDxyCCvQKsrG/6taO2SeQDaA/u5Bc82L67HFWefvId1MxUI0gM3MlglUQHYWv2poctg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-9vXhbzVq6KNF/WqyZa0qTk3I0Lf0rDRSSdDiUKBu3Ulmd7isAZOyWJcf63zPu6L8zC9ILbHWLMZQSY41LvhSgA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-iogFdazPKLA94A50ggncc1wR5ZhH3osTfLoHqqqxZsiSg2V0ys2aDW+h4k1uGRl9JfNrfgpJ/YTWTqhO4mqyHQ==";
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
