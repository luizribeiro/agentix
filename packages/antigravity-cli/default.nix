{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.10";
  buildId = "1.0.10-6349723456634880";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-/vBWEqKo8pNDAbe4c3tDVhNNNKzd+IYEbg1NfkV3wAcXqMEfjYT5WNmIm4dPw+5HVu5I7LoilWIxhXBfw+kGZw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-RXgoQPjOFCB+ybi5YuduZPDnTnkgAA8XYYD3IE4PieYcDkdcmitIWcyQ8IwhSEi52QrBw0TvmH95bidoIAeN8Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-le3F/mw7Rburp2g+dIx+rqXxlQ9k7s8IPNU/O0GWH88T/atoxk1wLX5bdJxj3GOFxbAVmoXtxu0SqdGjI+Ye4A==";
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
