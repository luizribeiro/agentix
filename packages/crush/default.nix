{ lib
, buildGo125Module
, fetchFromGitHub
, installShellFiles
}:

buildGo125Module rec {
  pname = "crush";
  version = "0.65.2";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-ASDzXUAIb6rc8S1/e62tvsEAAjevEdibZcMEvpQjsQ4=";
  };

  vendorHash = "sha256-eRLWNBSUMgrsFq0AeNzEb18Z68xOnASY9MwXZzONJqg=";

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
