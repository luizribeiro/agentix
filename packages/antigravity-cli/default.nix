{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.2";
  buildId = "1.3.2-5813501495738368";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-At1AnY1Ava5Klxlsge4Am5C75Gc644DwzSsrTv8FVW0GaOkYLW1h8c68igsMNZThHVFAcRdfQdcQEegrsxyfIg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-jcK7hHHPpjJuKeKJat12etLR83FDBLcPuucg1orwERguev3kOWSno/VMYEq3LE+tdyyFlWCLBZz8WC+2eYol0g==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-RMMxAfBe/JJaEsqHpcHJDFlNoF36EetLdH8i59R49OmmtZa5IHYmbEYVPq3IfUiOnb/DyumfT1DVII5riBSh1A==";
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
