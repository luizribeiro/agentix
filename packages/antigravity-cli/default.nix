{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.14";
  buildId = "1.1.14-6392696810635264";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-p+PLzbAdElPy/gwtcUpTMSkmZINRcHRu/bv6Mc2/vs7/Hrt0VnyC/ySJeFhdM3OPlmv257zfWH/MaJUvMjriZQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-SB9ZCxAspoR+8TuGXwjUVwSKHz8BhR7So4GOsJpTJksQfKXkQqhnckjZeQ/Zbsz0kYoq7YLYZrI9KUQiukL2fg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-YYnPYpFiWlbFEOgPV0iVMXIbyhUs7YOOaSVyXl3dnT0b/XSyw3nzKNSitoqRw4P4ZdegQz9we6i3WsD82WrqAA==";
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
