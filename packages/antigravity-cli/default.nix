{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.5.2";
  buildId = "1.5.2-4951595792859136";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ickIDybZm7lMKu0b9n4GEtx4A6d/xklj5slTd95t0NYmmTH0E6IasrqIXD9O6DQ3J1IMX/lHQDRawGtLcwhdZw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-qodsCBNXLvr4XtR5g8yTdBRwXUBJDL21T24lVlak+HRK445FeCPpJPqCcLNIEk4FIdPNo/7Ggkuy0UuYp6Bbqg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-mhQdp7IYxkCpYhiLOIkF8GXMMHQlu+/250wH+VJm+TUm9tDe6brYdreUMUA/WzDvTmUU9fRPvwbcoqB39U9hdQ==";
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
