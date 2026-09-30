{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.14";
  buildId = "1.2.14-4571742832820224";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-lTr6y1983r5o8C76bHMiRQ+z7PDPS8xldH068V6Jc7pY3yLEHoFRxyxugtJqjDw8pNaW7DFP6zmtg7409UioVA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/Xcd/HTd0HthyLCm/Xojj1OjoJilEFJYOgHZerhO5g23Qc5fBB6Hqdo8Gpqr6VsFMRM3RDffHiMXc1Unge2vCQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-2Wpn1pUqjsHaFsi2UV8Tk+0CYGWM8QTZtXuNE8ksWRMi7V4IpiiUhCvoGIgRbaD1+A3veXHJE9H0YjABA0JpVA==";
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
