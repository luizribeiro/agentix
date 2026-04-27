{ lib
, buildGo125Module
, fetchFromGitHub
, installShellFiles
}:

buildGo125Module rec {
  pname = "crush";
  version = "0.63.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-OAFdmBt7IHFym/anNs3Fu5RD3e/BtraPmanhTjowwFU=";
  };

  vendorHash = "sha256-7J2sQBRlPNNDewuNVETg8yDWe97v2TtUIUIj8yeDCuM=";

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
