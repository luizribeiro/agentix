{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.16";
  buildId = "1.1.16-6607970839166976";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-+jqUp9nZbLNnv2Q+zw2jtNa0Xz45DsbbHWmf2sT3dQiUYXFS/DwWlXEqNu7pJv/08A/0pE03Kz9gTPyexv2+pg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-c1TvWvMrfOeErGQQqgB1RAQKM6iAtQX7ustztBYFghLZv0jFl8yryIz9vCrA4FULS2sTrP8Ztt853hagLougDg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ZubeQ69XprBVtMLws0KNn/6l1dqhIilZEbQNP8i16VD8NGiu5dI5dSvIhPCLNFtFxVDQYmapbD0Irdtsfn4Gug==";
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
