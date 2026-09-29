{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.13";
  buildId = "1.2.13-6662628811079680";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-s2ZBttbnNNoJB7wCqNNcSgk6Rr3sYLbznrzMaXb8P4CuNXIRwc8Dc/nK5yLxpkqsd/8Z9ftIXJyXp/Kvz8txMQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-ehATSmnFddwRvcchMiNE6ds78snYkPLUD/C//ak9ObbvHHxIb0kdHd8IsSPe7zdce75GtizT+8PMlWsaO9IpVg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-omRjcVtYt4fvJNN3E4NRtyXpgMPexBf6pgrZkcjmdvZ8bIO3FY0u+VVpqHunnQ7y63gbbVOsLb+ZH1RD96Rlcw==";
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
