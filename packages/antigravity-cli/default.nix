{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.12";
  buildId = "1.1.12-5877618327814144";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-bewuq10xiOaLbCwcARu2mpUG4KIK5XXHUA8FiVgEL9JV0JaeZedueSjPQTleIVWAOCRkPfgGlBeIbS4iGK9tnQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-we57igKoUUQUL9uUKSO2OMR2dOy0lpwNgPgjF4RsTExpdqQwGGYi1vv18zqCernFpklQ0V/4MLXMPOSMhP9FAQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-/TPUSd38eRerTziWjNqDVtO8qfCxLuyWZeVlr0ykQBDPtLenbeTgatvvZwtIY7MNdYFOF97oVe/M5lHaIu7NlQ==";
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
