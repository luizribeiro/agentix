{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.28";
  buildId = "1.1.28-5576113066475520";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-hKO7mAsNlnZJ5mkysENlpXilVgneqVcjSaB7EUBnIWRHwfwvD/VZQPtmVzCdpmW9OvT+iqFq94huExJDtoQIfw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-qFXGI0Jv6QEIi/4rTVWbAfW0eafF7A5BrP4SnU/n3u6fvZBXByzI6MGe1lR0yvpPHRD83BT7uF+C8gw+yUKV1A==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-LMF8Ki3+XH0vgIisFsz+8nCTPHhEw8cXs+T0+Uhz+GXr3cWUNQjL5UtJdsD53EeMpxuMJrjAjWdY2VCHiCNVMA==";
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
