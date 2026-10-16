{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.0";
  buildId = "1.4.0-5281842794987520";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-g5rzO3KFVDq5wG+NH50r5vqygpi23Vqr5mvTHHmiH/RVSnR1icP7/6o2RVIJtTqRFtZQAD6BvMl9NJ7/q6o1PA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-bEspjCpptr0PWFZwMcxW2Al6Mr5UxLYzqoCtOVhxs4lhirOGDUugoSWZgxuCJrUbA+JY7i7H+uEFpFuOD84hiA==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ZN+yqWZevRm26daHwJRnO2HKn1/968gTkc6o44WHc+HIgVTwiOioaRIIVh2UanrqmsvsejvcqeXYpI+hl7CjCA==";
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
