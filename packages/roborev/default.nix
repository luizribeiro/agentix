{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "roborev";
  version = "0.64.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-DjfE50xer3qtBSWKbHo6HULxYKfD13tY4fPJ1oJO9eI=";
  };

  vendorHash = "sha256-/NSIdkeJrm3XSi9/KLaqEj1VrQOk+huPrWp8kxwYMCc=";

  subPackages = [ "cmd/roborev" ];

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/roborev-dev/roborev/internal/version.Version=v${version}"
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
