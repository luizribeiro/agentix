{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.12";
  buildId = "1.2.12-5784551402897408";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-krzU0ZdrVw1vBTobVxbi8pYsIso892V6P8tmsFsPVSP6LW8YmfFXwJtmq9osL4GTgQGtfNMYReHtqPJ3rdwrjg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-1fD+dDPLfEPqh4wHYnpP24LSGPO+9eZDYmb12f3S3xRVI0U7m+DEJQORpkoAf19C9/r/eXvCstUC5++0h044Og==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-4vEJYBl++/JFXtsShK5oaCHiRJCDZ/UHvLag0PYW6UXT7sXN8ptBu81/Ywgm0OniM/RXGE0WlvqR6B1qftRAyQ==";
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
