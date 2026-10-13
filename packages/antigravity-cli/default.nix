{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.4";
  buildId = "1.3.4-5524158944247808";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-LBafAnDKTX8MZqvrxJobYEfRVv9ojG0sy7BR6rtngePiTC/LDlNCQn0nNh7SDaItFZKCEdLu6AcPOYN7eruM9g==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-29rPxaHZh0+76johAm05kLRyji40h/0DFtxTyumjCRAj+WlCWCjz4uD63aQ86gfdl46pb0ynwgKt8iAfQZxW3Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-JKHUYzGXAfSUOy1JMsuGyjTWDS6f7c2QGMoxgJdz1xnyclEgaJEWMtsXXXIzCIVRAzvOzAoqVrG8+gQSaWh+rw==";
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
