{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.19";
  buildId = "1.1.19-4894004681244672";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-VLaw4uL+1dXicMY1P4CXvSoOlm8HlG3tgGWmKTt57HvlmT9dPeXBLQaDszgipcuId5UJT/osb3e7cYOBbJKulg==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-fDsxDIBoWty6cUmUIH64cPtIF0A5ddpGVVt9n63kRkh9o9j4l6oiDfvDD2AqtGGgFHpvezyCKP3r01lR4/JQ/Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-SIw9rBx8qGap2pkPmohki/txdpkqCi0nYF47wQFD5bF69VLtmfC/QlDi1p/tbQ1fUGhMcpvwPyafK1K0RQNVjQ==";
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
