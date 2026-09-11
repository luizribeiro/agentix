{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.2.1";
  buildId = "1.2.1-5123043593420800";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-RvdXuWtxKWrWditChEJ3x3hz4+rs3rtx5rMtjUn6CAx9+CO0cYy85zzC0fj5H2Fw/9rFiXi+BJdDrsjDXICsIw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Bin+aeaUmzVweTXvNdoBYHTqKaXZiaBfdAcT4KnpJ79S/x6toCBNMzh3mkack4trfFxE3i0pbl6NslXSZWjeOA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-9t1gV6gty8SrCHjZnEuEz8RcPi8SZH6vQ1Mi7N0Y0BkGILypQxhfVCQxuT809eoZz4To/bkC5kUp4RC/oKWkbw==";
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
