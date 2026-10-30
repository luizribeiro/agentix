{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.4.12";
  buildId = "1.4.12-4768735748292608";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-6FjPwC+1u1AKdgZD2icKzNKEeqmGt+KXPal60ZKLmdYvYrrSjAOeJbZeHKBz0nsvMLE+0JGdAyl3TrHg7ltHSA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-6gHHO3chh7ypKIUs+WI18NhG1tpevawYi5rnGVl0ZXN/MlVA1IPuXz9i0VECkAFxM0SXKhh937mMx7l/cgS39A==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-fK4xf7agLrOHmC8Gv7I0s2aHnPmoCtiWm1ceWlXR43pqWknNa3A8BEO7QXk3z147FKjIDLJpF6157vcjqfN0xw==";
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
