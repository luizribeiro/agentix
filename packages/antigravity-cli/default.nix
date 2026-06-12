{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.8";
  buildId = "1.0.8-5963827121094656";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-j8ZX7qOhPAZixhS6QFHwQFDLCrunVVUYqts22I2n070hKuTMbPQ5IDiyFlaJaXmuqzL4vwXIDmn8cgx2UQNGNg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-eEJqYfkpXXUoXZzdOem53Cc2NGRoySzoam/eG8x6nW3TLHvtGQOl3qzYdKBddbq/W5B+mRoRetY/M1SBE8Ybwg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-mCs0Te/S5jsI1KnvYIp3Cro6kumkEY0xjgCC8pdDRX6KFqrxwA98Ot51wtB671qPpdpmDkCMsZm0eod4sxIooA==";
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
