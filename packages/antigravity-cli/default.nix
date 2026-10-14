{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "1.3.5";
  buildId = "1.3.5-6164039479459840";
  pname = "antigravity-cli";

  platformInfo = {
    "aarch64-darwin" = {
      urlPath = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-jtFgV8m9nkUrmfe9QkpMY5WfqudeX6lLT5sb8gdp98beuOyciPPBeUTwm8+qBJULmB/LHraZS/Za50dyqf/ggA==";
    };
    "x86_64-linux" = {
      urlPath = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-D6X/fKhmHvY3naIZ3TBVIyew3q8RLqiWiC2quovWq/92/wl+97OCEb/7eL5ocfdJShc5txYLSDy2hIGiTUNcRw==";
    };
    "aarch64-linux" = {
      urlPath = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-i1fvUJvd327QKCS6jN9E7EvO/vkQZuEhXVw5VmGB0Q97kyBlRbl/omg1laWV4SMRsQzTTBLNWLOv7WXUpwrE3Q==";
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
