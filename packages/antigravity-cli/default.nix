{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.1";
  buildId = "1.3.1-4582356770750464";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-9EziuZNch5ZqhC9FR3sT5i4e+KIjEqsZAbGAvtiN1hX61ZQJaOgK/CZUC14C5XAbVVIUmeZMkVuj9zYzNpjWnQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-O4NJ1yZ4eVuvh4hIGBXiDXrPO4D50vhnpgfnErxr5/sY/X1Pzzru5K5ZOw9GloTG00l1JPEKTEJqGivewgsfaA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-xBuM2MUm6wQ/oLAZN3q4EJGQtUdiTxf1JVhorOec2OkZWmCse4lHgQESfv++BJNBxBCO0OrUsWCWhwSot52HmQ==";
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
