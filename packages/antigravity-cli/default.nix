{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.4";
  buildId = "1.0.4-6410134369468416";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-f3LIox2jBBEUaPQwI+PGEbmxA1lVqRVeX8D6dwgwl24qI3heFfAwQYMbBE/vLuwjvb+iOUs59s1UHZ5EnaHH2w==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/ZWTCwY4TtS1Zy0ajzIEHM2WhmMBh9mB23FyGAoqC7d+xjqIetxmKR0ry1D/WwikmWucusxYnFbIYcQCCdV/EA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-z7vsPP78GN4/DVe8ccKBk6boBOK6HGwxnbZ+984YIBOAkGy6QktMu+B4bv1XTiyWd6NDTcsQbNKTFAFVE5JaQQ==";
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
