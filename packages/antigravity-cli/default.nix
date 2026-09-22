{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.8";
  buildId = "1.2.8-4907747922280448";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-DpIsrQSKkrLIULKR4vOgrZnC/T0HzpFweQsjyLcb0rRYCalqLkLkc7WL8QC7dNFqTffJSLSOgDQbe/AVbgXVdA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-KND4ZhMWhQ0eH/VB3F93J+Xfbqny0ooMm1VnqmOKd4sh2SKRI8Ze5bXGRtQ5C1iSRbH9wABOmPDNF3SqOBR3Yg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-Sibmy0D2iZXTpValFB62ax3iP6GopkduCi5pdqsZ35wOJXy4bnPEitpjvY0foZcaPoH9Iz2jOpU3dtF0QEPj6g==";
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
