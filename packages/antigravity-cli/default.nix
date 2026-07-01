{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.15";
  buildId = "1.0.15-5090589570629632";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Puv5//MKzSM4VvNCipxgk+nsMJSlXlvzTxbtk/7L8l7f6fDNjHTl8dIHWPas9HYLAhD863L4G7qfvf7RtlMg+A==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-YOBrdmwV2luUk1DiMqzpJTv9+1bBKn+3pptlOHEGk27+pJ2Ne7gTZ+z9yWfGYkL8RfQNNOt/+1lH8H8Pv4lphg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-F1EHsbjJlsv4Tl1IxkTIW/EDP0eSIlSNcqxaJKKn9gpRRr08N9OFj6/oV8SqN2W+TTZd4hjXFnpiBF2+qzsLww==";
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
