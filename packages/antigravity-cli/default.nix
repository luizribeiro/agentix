{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.11";
  buildId = "1.4.11-5180209989812224";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-/5TNoC1GhklQJD08e0l/wT2NUDb0fgIJnTESIoqEHx6CmM83+/0/cLJcJkt5QAYAkyslmfmrpkm8bHzzyGf9Hg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-KTVgHvp0XtbjFNMrQVxx9E2dRV8OaiWDNyWEvlqQdMKBVM+B1e7GW0QWV5RTo7OwXTq+TU8XZ1TV75OoSvbPKA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-pfgNduqVs5c/Taq29//Yjxz9nH9/cN2pUbp0sucwmlP2TSIkoNs5yUnEt098VqFqOrBPpLj+1qRddIayaSpOJQ==";
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
