{ lib
, buildGo125Module
, fetchFromGitHub
, installShellFiles
}:

buildGo125Module rec {
  pname = "crush";
  version = "0.18.5";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-qfV2vanAxN2+/zRiInY6ndTbiSrlT/FU1p8Is1Ywnj8=";
  };

  vendorHash = "sha256-6/DvpfhW1Lk3SP7umOxeWBJhUtX1ay7pkG5Ys8M9xM4=";

  nativeBuildInputs = [ installShellFiles ];

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/charmbracelet/crush/internal/version.Version=${version}"
  ];

  postInstall = ''
    installShellCompletion --cmd crush \
      --bash <($out/bin/crush completion bash) \
      --fish <($out/bin/crush completion fish) \
      --zsh <($out/bin/crush completion zsh)
  '';

  meta = with lib; {
    description = "The glamourous AI coding agent for your favourite terminal";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "crush";
  };
}
