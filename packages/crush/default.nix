{ lib
, buildGo125Module
, fetchFromGitHub
, installShellFiles
}:

buildGo125Module rec {
  pname = "crush";
  version = "0.62.1";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-kPG7NZEZ/uHhyx9GYbIkTmybfvTPuD+TTlWbRFQ0HzA=";
  };

  vendorHash = "sha256-XlSHxR10ov0uvnqvu99Ax0kq/R/gnkX8fLaG98tTpe4=";

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
