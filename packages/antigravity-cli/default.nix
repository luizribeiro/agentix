{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.3";
  buildId = "1.3.3-5524738307653632";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Beu0chScpGHpn3hwzoH73UjjhE9DuWp3jJgdmDQhYnxb0CWW3IIRzNMLTO4N+MpNF7aB9YfvIpSOpMcD6cf8vQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-q+Pd9c8w062qWGrPUFIhqhlwL1ynGvPIsfmxpZdr2OXBUcQeozs5xBZ10lhDRio+jDgsBU9YDp1+FoiRnTtREA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-G/01A1diGaECF2wTV5ZlovOehKyGqQSxF9OzPz3XUfGUqGJJa61v/pFK1G0sh3uhK2wH5tsHEotwbSOCYv5DDA==";
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
