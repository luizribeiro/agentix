{ lib
, buildGoModule
, fetchFromGitHub
, go_1_27
}:

# Upstream's go.mod floor is above nixpkgs' default go. Drop the override
# once nixpkgs' `go` reaches 1.27.0.
(buildGoModule.override { go = go_1_27; }) rec {
  pname = "roborev";
  version = "0.66.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-qzI2D42m+zRbFnM9anP2HifCK0EwplbPOsOpng+DHJM=";
  };

  vendorHash = "sha256-A5ZcODNZyjMTTFI8QZqaYn0Wddr8+899R+C1n27TI1U=";

  subPackages = [ "cmd/roborev" ];

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=go.kenn.io/roborev/internal/version.Version=v${version}"
  ];

  meta = with lib; {
    description = "Continuous code review daemon for AI coding agents";
    homepage = "https://www.roborev.io/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "roborev";
  };
}
