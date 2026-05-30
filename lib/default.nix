{ lib
, nixosSystem
}:
let
  overlay = final: prev:
    {
      codex-cli = final.callPackage ../packages/codex-cli { };
      claude-code = final.callPackage ../packages/claude-code { };
      gemini-cli = final.callPackage ../packages/gemini-cli { };
      antigravity-cli = final.callPackage ../packages/antigravity-cli { };
      crush = final.callPackage ../packages/crush { };
      opencode = final.callPackage ../packages/opencode { };
      pi = final.callPackage ../packages/pi { };
      roborev = final.callPackage ../packages/roborev { };
    };
in
{
  inherit overlay;
}
