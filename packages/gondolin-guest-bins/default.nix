{ lib
, stdenvNoCC
, fetchFromGitHub
, fetchurl
}:

let
  pname = "gondolin-guest-bins";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "gondolin";
    rev = "v${version}";
    hash = "sha256-45oYCfwvd6/s0NIMyMklikTnN+7twqVDMpwZYL6VbhM=";
  };

  zigArchive = {
    x86_64-linux = {
      url = "https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz";
      hash = "sha256-xhxdpu3uoUylHs1eRSDG9Bie9SUDg9sz0BhIKTv6/gU=";
      dir = "zig-x86_64-linux-0.15.1";
    };
    aarch64-linux = {
      url = "https://ziglang.org/download/0.15.1/zig-aarch64-linux-0.15.1.tar.xz";
      hash = "sha256-u0qNKtc15/unZMSX3fQkPLEp/s5BSNoyIqcEbT8fGf4=";
      dir = "zig-aarch64-linux-0.15.1";
    };
  }.${stdenvNoCC.buildPlatform.system} or (throw "gondolin-guest-bins is only supported on x86_64-linux and aarch64-linux");

  zig = fetchurl {
    inherit (zigArchive) url hash;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  sourceRoot = "source/guest";

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    tar -xf ${zig}
    export PATH="$PWD/${zigArchive.dir}:$PATH"
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export XDG_CACHE_HOME="$TMPDIR"

    zig build -Doptimize=ReleaseSafe

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 zig-out/bin/sandboxd $out/bin/sandboxd
    install -Dm755 zig-out/bin/sandboxfs $out/bin/sandboxfs
    install -Dm755 zig-out/bin/sandboxssh $out/bin/sandboxssh

    runHook postInstall
  '';

  meta = with lib; {
    description = "Gondolin guest control daemons";
    homepage = "https://github.com/earendil-works/gondolin";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
