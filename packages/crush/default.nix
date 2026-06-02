{ lib
, buildGo125Module
, fetchFromGitHub
, fetchurl
, go_1_26
, installShellFiles
}:

let
  # crush needs a newer Go than what nixpkgs ships in go_1_26 (recent
  # releases have bumped the go.mod toolchain requirement past 1.26.3).
  # Pin it here so the overlay doesn't have to know about per-package
  # toolchain overrides.
  goPinned = go_1_26.overrideAttrs (old: rec {
    version = "1.26.3";
    src = fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-HGRoddCqh5kTMYTtV895/yS97+jIggRwYCqdPW2Rkrg=";
    };
  });
  buildGo125Module' = buildGo125Module.override { go = goPinned; };
in
buildGo125Module' rec {
  pname = "crush";
  version = "0.75.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-a5SItUvr6kRlF8mzP5a7tRvULCAvclvK+PcyL/USbWA=";
  };

  vendorHash = "sha256-4zJ4mXVefVNHonTPDx8HCWtmymXJF0Z44Sm07/cjBx0=";

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
