{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.6";
  buildId = "1.3.6-5068262057312256";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Rzo0toXQoJ1IeQ6Lhrw+VF36uIn+DY/IHLfh/fwzb+eM5XAi47Q4x1TJPJz/6xP9vRd+UP3twIfVJzL6VHUYPw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-D5Xy/yR05ZJuasjQZhoW2rLdMVllGMaNaHs9DMttpRi/lP2Gqizlfyj/B6hSnpsmihKyFwcLrItEgZ3OiE6TIw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-2+lYVGC6jqMJWcaiWZ077x53EDMe+MnkGIY6MA0ZNRkG4WvmMgT313Q0x3N5a1riIq4TWsAz21q/FUKwdtArDg==";
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
