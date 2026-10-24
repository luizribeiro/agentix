{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.7";
  buildId = "1.4.7-5900205422411776";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-AZLJkw/I7M3ceu2Wpq/ekV8p7jgMgba2qDXmjk8ZUFFNmKWWqH+6ubHYe6JJIeKTJ68GS6yM7Qu4c+eCQ4Jt6Q==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-vtp2BYdYn1gnsLUWw+wsW9XNLpHrDiUzgHuh6ZCifc1jrvAZHgt2+2D+qw0W6qghD7eYQsNN1ICeJX4XEu3RUg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ap+g32MAYzQEVx9m7HkkCYzHCp8jrFXDZZE5u8vdLqUwH+Hvco1MBk+sZRBOoUordEIfMgqC5bzyGMSCtY46Fg==";
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
