{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.1.21";
  buildId = "1.1.21-6424454201475072";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-D9Lqofxp2f9RyeVzmGg+gA0a06MXOkM8MomZorSJVVmP3LIdJUfAX52FOiQKz0IqF5iy1wRgdBW3seuPpR9Gqw==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-PedVLvCJwTbA9XDNycBGUieOAsHUHtORGtX58bjDvVZ2Q6pAGhkWBg6jKhsX+6+Qy7QXBx2zP0Z4gPzYSIaNkg==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-HQpnPIOPMjUYe+EpLCDUG/O+AcRdnXRdX7aHPiAoNgfcNU+iC3eq98aBRekC1LDfarFx2Z6Ra9Umkcd6Q803Qg==";
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
