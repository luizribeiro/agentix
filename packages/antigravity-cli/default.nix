{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.4";
  buildId = "1.4.4-4783783166214144";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-zRLEYJuLRKqUwv5Q7tjziE8azlBlhGMMv/z/QosNVXuIPbDMX7nPzJJSiCnFGYV4KQcFkMFe1tZzrfGRbmCREQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-fOFJ01A0TBBGx7WbZlm8xdZZ81G/OgfGwIWIfZNCfOuJ2Sd1LkzNCES1P/uR0z1qSfcoNc6ydsfP/dE8+4AjuA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-e/xPfl4t2kzQxTbHLPlyXCkYoDgCitEfpPf15X23fp/31rm+ygXNhWGLd90+d95ktjYp0z5XefKRETkNxTx6rw==";
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
