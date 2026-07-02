{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.0.16";
  buildId = "1.0.16-4893150192467968";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-mCUJnai4+TtYnRfp08FEvogiPZY0GyILSDt9iBhE9gcDkmO9I/ovAqmgOX7XS1ZjTa3Iw0rqu6tFyut8NMjX8w==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-LjNi+zYNNQKFw6eYkXcmUupWYIEh5OiQkavlU+ggPDeeMLrIa94QnswLMmbLbrhxpo7yipk67KeURFbw9yCuMQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-iWYQQeY7IRzTbT1CAMfzidOwVXOkn1yFiL/UK+zk9Mvhz0EI1sZkBz9YT/HjeXwXgVCuAaq2+lf0HB43wj+GhQ==";
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
