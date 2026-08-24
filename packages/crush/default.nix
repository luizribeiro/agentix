{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
, go_1_27
}:

# Upstream's go.mod floor is above nixpkgs' default go. Drop the override
# once nixpkgs' `go` reaches 1.26.6.
(buildGoModule.override { go = go_1_27; }) rec {
  pname = "crush";
  version = "0.91.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-iuUBdY9ouyPGR0jDzrTvu7UJJfk1GIwCV8om8ZGiB+E=";
  };

  vendorHash = "sha256-+UevSHf4pdKuvKkuE5YzIcwhVHpix1S78iIxVZPmxig=";

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
