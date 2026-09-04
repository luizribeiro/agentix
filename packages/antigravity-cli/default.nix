{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.26";
  buildId = "1.1.26-5550154686791680";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-iQJ8YAxwD7qDG69DhDYmtJ56Fq/V5/+2gkQbG/KJT+IeayMU5gFQHlaVVOlBkJdvqYSl9oJxqwTi7nB0+bb1mQ==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-gPLnvx/ggzSHl1syCwcXa4LdLMIEO4rLQgGze4bWBK9QcYQAtYrw9BrcaLOJZA9v+VNi2oep7xaCs0JY6DEQsg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-My3dsGq02QGkTP1LmzWISCMOZKZFFajnmwOCI0itrJzpLVTLT8URnvB17fupIoIMkm3934LTpJ9OzbbmcE38dQ==";
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
