{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "roborev";
  version = "0.55.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-zGkF/rSlyl3Jf/zbVoUeph+34VV1Hg5gEHGrh5VDes8=";
  };

  vendorHash = "sha256-mw5kaDLPlMU62twP5FjRaXp+6+CVd9toybW8LZ2rNxI=";

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
