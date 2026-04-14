{ lib
, nixosSystem
}:
let
  overlay = final: prev:
    let
      go_1_26_2 = prev.go_1_26.overrideAttrs (old: rec {
        version = "1.26.2";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go${version}.src.tar.gz";
          hash = "sha256-LpHrtpR6lulDb7KzkmqIAu/mOm03Xf/sT4Kqnb1v1Ds=";
        };
      });
    in
    {
      codex-cli = final.callPackage ../packages/codex-cli { };
      claude-code = final.callPackage ../packages/claude-code { };
      gemini-cli = final.callPackage ../packages/gemini-cli { };
      crush = final.callPackage ../packages/crush {
        buildGo125Module = prev.buildGo125Module.override { go = go_1_26_2; };
      };
      opencode = final.callPackage ../packages/opencode { };
      pi = final.callPackage ../packages/pi { };
    };
in
{
  inherit overlay;
}
