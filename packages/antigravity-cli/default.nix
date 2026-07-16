{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.3";
  buildId = "1.1.3-5723946948100096";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-gTmCEALwVfirN7bkk35Sdb4bOGciExRr1V22F7faunnJEhGPXc7O5pj07IXAdX06VqlGyErSzjDV3/Zwfg0CiQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-+E8E+lDHs7JXxtCRs/ZkJeB796pVb+L521iZqlQgUR0Orfct/rJYFq2SITsG5QObfTPoAlz8Lxs9d/sz8tFhvg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ILKX/d8P6r/pgt5hAlCSPPNbnBdW42rwBodrKkpHWnzFmljG8E2R6W6jGkIrYAIMRE1EPxYzN7ruaf/JtvM2AQ==";
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
