{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.13";
  buildId = "1.1.13-6057583128215552";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Mh4DQlUbDRGXodazc2PRnUt5k23rEDUjxs3aR88aNw3R/rv1ERsRItgygdMJSbbvyNzAO7cpSKipFSvAzow7FQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-icaIG2wZmcuCNucYHCGSro83KwQTOWwPe8/4PSesnAzBICeVzA1insHsv0k30cKUz09eT5+OBbHpcuJxmDE0Qg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-0vNkKHPjKDJl6/TU4syMNlLf9aCxk6M+v+Dd7WhSHdArTCjtkv9UeE9qYmfpXIB7TYGU6KbWGdQ0hjirXIENRA==";
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
