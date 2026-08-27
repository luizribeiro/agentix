{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.22";
  buildId = "1.1.22-5711547746615296";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-qBIRhb0cNFVBCtQeiOIDDqI31Ja45AzN4xO/YRwFUYQP3fRQtFyOGiV12YY8mQszJPGe7w9HmTbfi/xuToDTCw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-QCJdSx8AlBLpBfCiNLo9UUhwONGtG4+hkzHIS+VWEKAfWwrZkW+4cRUcxFRWxrwwzAsepdq2wGFryPsmK83XqQ==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-s3pxgzDrXicOHKcBNb+WSkB7pib7/3U3rFjglOoxvGI+bSFu8ZcYj+i1xG5vV67mSjt8niP8hVzv7kP+Q0F50w==";
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
