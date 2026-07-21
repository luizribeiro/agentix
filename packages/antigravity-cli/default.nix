{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.5";
  buildId = "1.1.5-5958982624477184";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-1OM/UqvYpP0JTsOhKzG7G2V8pPsrn4qndAxA/kf1dSZ+sKJNNSY/3dQCdXUBNnAAHJX21cI/39/CzlCYbcY4xA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-kGv/Wcc77WMCdPZ+/Hfj+iBk/hJvTXUhx+WNxnc9jR886GiPEXj372V3Zyj3gqjrwhEYlhfPu0Ln30j1YUrR9Q==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-YF4TlwfhC87P1BXykLN+4xlnGCyQmRi/gQP7kCzRKE1orw1jAolPxY6E9HaQ8lnYEJQ0fESGt+pBmmCO6v/r7g==";
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
