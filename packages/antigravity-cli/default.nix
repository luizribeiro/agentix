{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.1";
  buildId = "1.1.1-6269367663591424";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-KZPEtD0nA895aEjhoCtx4uBYg4fY3CQkQ1IH7tu8IJclHKC6MhuZ02Q1j35umN8awXV8H17ayo1Tq6omEj5/SQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/OutgkfgRTCX4rJtg5NxyI3wQOb7GPrD/YByhRGUc5z0YkBBRptX9Sm8nC4RQKbOTNXnFE5k5u/FYFqfEKhitw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-bT2Jx7iNTiLi7vk3znMTRSmWV6x6FCNqk6X53OZ+tyUYRczJgEsKsYgRJf9hZTEc5zxpM8E3bsO5ZmWalHU+YA==";
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
