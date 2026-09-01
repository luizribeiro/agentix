{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.23";
  buildId = "1.1.23-6260551186251776";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-UJZ5XQ1G78B8EolNkkXCOcJUPNsSRPEx2+WkqusSrzFwojFFFDM9+LLasMKfkJ9uVbgM8pJQQlqD+5RuS5olMA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-iSV7vHVfTJe9wBjl7hKAukKF87a8HkoYbEN5CnhZ0tAFgWteIvfIXeMpDln4usMOhxh+KcuTzlO8XqPn28h0RQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-/hOUNN2jYkHOPTvJ96mGurvXEoz6uEg0bgSirAY2IKluS+shYYxOApTYSbrZxq0BxOrI5htPC8JAzHUeHz+7pw==";
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
