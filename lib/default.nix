{ lib
, nixosSystem
}:
let
  overlay = final: prev:
    {
      codex-cli = final.callPackage ../packages/codex-cli { };
      claude-code = final.callPackage ../packages/claude-code { };
      gemini-cli = final.callPackage ../packages/gemini-cli { };
      crush = final.callPackage ../packages/crush { };
      opencode = final.callPackage ../packages/opencode { };
      pi = final.callPackage ../packages/pi { };
      gondolin = final.callPackage ../packages/gondolin { };
    }
    // prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
      gondolin-guest-bins = final.callPackage ../packages/gondolin-guest-bins { };
    };

  gondolinGuestModule = import ../modules/gondolin/guest.nix;

  gondolinHelpers = import ./gondolin-helpers.nix {
    inherit lib nixosSystem overlay gondolinGuestModule;
  };
in
{
  inherit overlay gondolinGuestModule gondolinHelpers;
}
