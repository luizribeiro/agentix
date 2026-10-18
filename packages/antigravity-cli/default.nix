{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.2";
  buildId = "1.4.2-4835981233356800";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-KK608KTFDYxZGwmMObmoWwnGNzI15D4nZp6EV4z+oWFul+HurkD46WlQpl+2tR+N2RlImLS8afEIRCXXirzUQg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Sjk6/BNpzulOgXwbQwyRKNArEuvU1XA6zlzUeyMz4hbWc/sAl8v3GV91exEBY7qYUOnuo/27rd1LJWaLgsA/BQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-9GVUaNMwPmA5y88aMHaePLXE4W0Un7oNCOg/kfDysHy2I6StuGFcp6j8c78kRTAeDhq4LqifaqRMvZqelnA+GQ==";
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
