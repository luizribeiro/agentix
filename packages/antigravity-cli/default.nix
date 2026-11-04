{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.5.0";
  buildId = "1.5.0-5269980577660928";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-gzoKGKQY9wufuLKxpMTcVx8bFotRBKowN5RjaVlGzMAgHNSPnP0wIx62aK5tB+/htJphnMqhT37ihh+eBJ7ivg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-5gMfhQkpIQcF2MI5OlZluCuMOxloSm08VWyvox8m93rL8WTf7pbKhKWudnCsDMI4qXTJgcUXsmkZS9zP8nHL1Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-UJUYsoIJRdsr6l4BPKQ6Sd9ceJJ8OsNBoRFSh9UmJzVuHpUGrA0gQPtGeRX7pN3pAGHQkf3b3fjdwhJjeuQBUA==";
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
