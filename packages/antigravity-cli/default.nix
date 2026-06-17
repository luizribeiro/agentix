{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.9";
  buildId = "1.0.9-6003845613092864";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-tXvK9uyS+zftiTKJUdlI2yAHJzlCH+X1HIwjwoAqC+Hs7PE3mQ6tpzRiorOdoSsSrduzyvYn9UxMe3BAqSBLnA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-nAnu+QXqNAeZiJCAZ8txaq6t84B+pXJAPXksURNTMhP5j0MVnWNnlAiBmGm/4UPY4nieP6sPKFk//QTyp9z0ew==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-4LE9DMPxM3li0d/38D9EssRLXgfdSDyWM6ACNde1yCV8bcXghLEigaqhjhyUqoFgLJlO4ZtdLjdrwk2F9Wk3LQ==";
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
