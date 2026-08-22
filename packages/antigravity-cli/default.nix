{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.18";
  buildId = "1.1.18-6435547766456320";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Hx0HeOL9u7RFrQDyWBjTR5gjJOhjOVRkQbVyeTPMgDIbTnvBSw4KkE+kOEbvBOtUlAcTAOX3osvSb1386hRaCg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Juk+7WSqVD1CGmrpkI5SrUBui8afCtnPt9fRQWDyiEHsu57Ad0cpnuonFYGrYGXu5NjggrgUTN+g30VARBB2Mg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+iD3lMMtZIXvABu8fPYNj4vle5QbL4274gz85LkHDoY2hVBabR4FDb/3j+QSKHygK899V8+s2+jLGkXrs7rzGA==";
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
