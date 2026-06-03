{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.5";
  buildId = "1.0.5-5009297080451072";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-XQ6KL+e48NBeLonsPBywLyXSydBV0dzYArbLsUEVWryq2lVYXYD1juY6Wma7JNYz+bboy1vTvGYJTo+6uBWjBA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-cggtiepx4QHHvrFjAkFCjVP2jHAplYl6K79V8WKp9xyNLX+Y57MQRJz72wsFP24bhpwfjZ+yPJWFHpgNVj2JJA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-j5LtbiYWbdq1lbOXXkfpH90cC/c7OTviUodjHMrgcCpjcuvqJej71Jl6v22budIzaIaKW/oMeifL0hEJgcUBmA==";
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
