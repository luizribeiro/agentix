{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.5";
  buildId = "1.4.5-4952523841339392";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-yU7MxPASF4fmLpa0ZCbBfftH7KwyTMXvP5ERMSuNygS/X8f1C64XJwxIaVZ5iuwLOKX+o1mQydXbQV7JCviMjw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/TDo0lbijEptD1/dqg90tHyMWo6foihcsD+FCT6Q7KBAbxwvpXoDhruCDiHtQn4nwjFaAUU9/aQBwiI7JjmrMA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-z2AAS0gBWic33LVs4RIn/vOnIvLpMpwTMY4pCVHjUMOVEYvYaAwQQrL97p0urQX7hLsllvotABKkS8BoZV006w==";
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
