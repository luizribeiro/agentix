{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.8";
  buildId = "1.4.8-5447777392656384";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-RUtGkYOkBW/xKhVEjFzTyy6ZvBGmnfMBO+l9Pk6j0eDk3XrJE/nd/80LnBDcnuHdzHZv/a4aaRqM8XIx9hld8Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-sjaDdxQ45yv/4KIjEWj2Whag1z7Sx6hGCzEdxf4MPJ2d/Gy/t9h1UXM0AHGqTMXHpVL7XRvj/dMcK3VZ1n5ASg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-eD7p7dD3PoU6+XfihIKU/7l7Z7Me4Z3Mr7AB8D80sDM3GiuzNxtht4hDxhvUgX7x0oY6LTcbJlE+oX2SHFhL7g==";
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
