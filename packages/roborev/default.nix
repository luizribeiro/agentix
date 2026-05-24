{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "roborev";
  version = "0.56.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-VSIY9v23XqX4BRhUJr/Aw8QGg1+RVDsZvK0LxTAPC4U=";
  };

  vendorHash = "sha256-b6B4hR84k3rluvfIP8gRdJpfepiH7xKCRKblbKTHHWc=";

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
