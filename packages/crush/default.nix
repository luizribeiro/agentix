{ lib
, buildGo125Module
, fetchFromGitHub
, fetchurl
, go_1_26
, installShellFiles
}:

let
  # crush needs the unreleased Go 1.26.2 fix; pin it here so the overlay
  # doesn't have to know about per-package toolchain overrides.
  go_1_26_2 = go_1_26.overrideAttrs (old: rec {
    version = "1.26.2";
    src = fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-LpHrtpR6lulDb7KzkmqIAu/mOm03Xf/sT4Kqnb1v1Ds=";
    };
  });
  buildGo125Module' = buildGo125Module.override { go = go_1_26_2; };
in
buildGo125Module' rec {
  pname = "crush";
  version = "0.66.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-owGodQrtzhv9DIseTY4HinLDfTS7SUBWQpATSCu44no=";
  };

  vendorHash = "sha256-moVpfFscZLz7mQw+pqaG132k9KTNyRdKOFNNd0RN1oo=";

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
