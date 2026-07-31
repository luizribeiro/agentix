{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.9";
  buildId = "1.1.9-6572839516635136";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-S7XHWc7H5ap3OPnVJZuym8iJn7YWoJeb5bGS3a3p8UPUk+3jDcwUdSmO9AYMATv3Wpkq3AQb6JVXYrLFowYfGw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-O+v9b9qkP/930z4Skn89srFEmwCOQ5jbuYbqXuc8VfzlEt4i2acRhVRk7E/Pw36oURPkckimEOU8Dm1eUpftlQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-nSirfnZ9diWojsdNchSHR856wyCJwaePQY7b7Vo1oXQ8BehklRhLZAEQoGxdKOiTPjUuoV4INt0tZMjhz2jxmQ==";
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
