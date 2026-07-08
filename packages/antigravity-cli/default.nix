{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.0";
  buildId = "1.1.0-4523441756438528";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-y0d+qaVW2ebWfuIl/3VpJV93l2GyxtT/tCTnPQB8CFgy6atPMLVC3A50tYNwxFE9vnhcXgXT2QU8/wu31l9IGQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-S6raCOUgl3XeFvUBL5JOP2bZydmeHtp4IF2j2bUnIlRSgEo9Vz+lSBDiouZnKamc2QdkQpSGJaMJgqzJI4HzAw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-UW83SlZJU5bRNQs0hLSxbeT4cnOmeaDeDEm6Bpg6A2H+Fc+2okklyv1tQKZIFX79DB8gQbM0XmBGjUy4XIm5ng==";
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
