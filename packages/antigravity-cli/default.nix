{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.10";
  buildId = "1.1.10-6423386432339968";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Yj+fu9kGmhrQ1xq35iNbWyhuGbEGfkFk0fm7elzoZtIeSpVduo7jl/6viwdnic2WZNomFpmF77WsfUKQGGgL0Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-5k1OWO3g+EQPKz3AIfnW02sF9cL3TVqSFcHxGyDVNsjC4CD0zlJXqmfpQOlMlNWhbTqmRhzaGO5/PnTTogyhrA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-LWTE4J6yLIJLwpjKYeSMsOYmiDU9tBIplrLku6jJoVcNLL9uZFLtfvMN8JQL+PBYeJ5Gau1SZMGuLkYT7KW1cw==";
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
