{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.24";
  buildId = "1.1.24-6130423206641664";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-fWLOGJg0OEM7EuUU4uzSPwPf+TfNtzyOU7cYr98crRjwourO3e+rBoKtBJsfNV1w2mBe9NNcyp7Hl57NyGVvmg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-7U35HqfO2YaqFFB6CrgiXZKYUZD31VEBDroMRsVpWH5gLLNq+Byc3nrw1rOA6N06ghMTYYBs2WAS1Eo+R/s2mg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-MWygDVA4mgixYsZgZrTi2yAeT/uFrOoFAp48RTLGnVuPfHQc8CcyWIn4mOqPdHr4zRXIAuFfz11ztxN7biQgoQ==";
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
