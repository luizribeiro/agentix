{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.9";
  buildId = "1.2.9-5905287731871744";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ipYHN5zI1lNWmbscthlc2tl77njy9RKFpq8xzgGocbQk3lbOwb3HxKVfAkiBuZiWOLUqWB6bIJJbYG4MNpNH0g==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-deg9RssWMtpKyim3hQF3U8jC37AyAWbaayyAB2eJgpQ1FeZMiCT/LYUQ2bUusrPCfzBq7sWMSk9PiqVVDLDLEg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-Uk2vbOYTjVhFXzuC66SSOz2i1Ph07aMadpn7AnXRjePUrm0sOsxLQ/2wY/bFGtqrQnhQVM0YUrhFWJL6JATQGQ==";
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
