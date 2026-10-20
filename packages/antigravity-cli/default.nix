{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.3";
  buildId = "1.4.3-4577820882632704";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-9o43fS+MgS4wH3gQYZuqLJbVAKNLqwLl4Xt1LC3zhW2oP5oyvjUEEmW6GhntbK1r90LVhQPhJlFPs4lhm8KZEA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-m3JrhigKVuj/qEs7OhwA0ZlygzofbAsh2FxfxuQIr2SS5MYTU8rZtQC+5ZmvJkySz8Lq0fUEirlSUyjh5BmcQA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-qQbvKQ4HeHGzM8tvE9TXbM38A60V8BLWt0XAL6Rx7cJ8ELwwWbhxQr9t4LrNZDKPYuYI1XNmVVJLl+jUtKCIKg==";
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
