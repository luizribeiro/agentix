{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.6";
  buildId = "1.0.6-6458082025406464";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-3k/XXkeDPPHxRYu492NI49zD+GKjvGHxgb+MRNlQPImAy2m2hxUfgOIveaVc/AfqeUq1T2ZY2XqsKzk6OCKiuw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-G1eXe+CDmLA0TvUBkIloPAqumClUXN8wVsmh0CuUnqmNtuZD75bvT2h3ZU9NSNUmcDXviidlKo4CP2W5HAbfdg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+ZZ/qMMYwx94vML4E8dU4Ob3usgDAURWHVswMVVyDajKBIXspLbIFCmRcFJqHozJ3J7CCR/Mwem9uGTduWEHVw==";
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
