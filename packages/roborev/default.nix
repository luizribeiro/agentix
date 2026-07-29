{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "roborev";
  version = "0.63.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-1EmBcNryEZA7B8lEKlVk7JSDRI/9KZj+0HusiEgZyi8=";
  };

  vendorHash = "sha256-lHkZ1POl+oPihDjb4a1INfeiJQ++rmN6SmE4Ko45lzI=";

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
