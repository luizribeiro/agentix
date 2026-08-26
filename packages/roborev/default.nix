{ lib
, buildGoModule
, fetchFromGitHub
, stdenvNoCC
, bun
, go_1_27
}:

let
  version = "0.67.0";

  src = fetchFromGitHub {
    owner = "roborev-dev";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-OOKxu7xz38lw80uaIUfgbOw9nNioLU6ouP9lsGElqCg=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "roborev-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [ bun ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress \
        --os="*"

      # bun populates these nested link directories from several workers and
      # loses the race often enough that two identical installs disagree.
      # Nothing resolves through them while lifecycle scripts are disabled.
      find node_modules/.bun -mindepth 3 -maxdepth 3 -type d -name .bin \
        -exec rm -rf {} +

      # A git dependency's checkout keeps its own internal symlinks on darwin
      # and loses them on linux, which hashes the same install two ways. Links
      # bun resolves through point at a node_modules path; these point within
      # the dependency, at its docs.
      find node_modules/.bun -type l ! -path "*/.bin/*" | while read -r link; do
        case "$(readlink "$link")" in
          *node_modules*) ;;
          *) rm -f "$link" ;;
        esac
      done

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-TF+Uazmz8/h13oVRd5dvfvcb1J6LpKLsB9qNIo+ewCU=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  # roborev serves its web UI from a Vite production build embedded at
  # internal/web/dist. The source tree ships a stub there instead, which the
  # daemon detects and refuses, leaving the web UI disabled.
  web-assets = stdenvNoCC.mkDerivation {
    pname = "roborev-web-assets";
    inherit version src;

    nativeBuildInputs = [ bun ];

    configurePhase = ''
      runHook preConfigure

      cp -R ${node_modules}/. .

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      # Hand vite's entry point to bun directly. Going through the .bin shim
      # means the kernel resolves its `#!/usr/bin/env node`, and the linux
      # sandbox has neither /usr/bin/env nor node.
      pushd web
      bun --bun node_modules/vite/bin/vite.js build
      bun --bun run assets:check
      popd

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -R web/dist $out

      runHook postInstall
    '';

    dontFixup = true;
  };

  # Upstream's go.mod floor is above nixpkgs' default go. Drop the override
  # once nixpkgs' `go` reaches 1.27.0.
  buildGoModule' = buildGoModule.override { go = go_1_27; };
in
buildGoModule' {
  pname = "roborev";
  inherit version src;

  vendorHash = "sha256-A5ZcODNZyjMTTFI8QZqaYn0Wddr8+899R+C1n27TI1U=";

  subPackages = [ "cmd/roborev" ];

  doCheck = false;

  passthru = { inherit node_modules web-assets; };

  preBuild = ''
    rm -rf internal/web/dist
    cp -R ${web-assets} internal/web/dist
    chmod -R u+w internal/web/dist
  '';

  ldflags = [
    "-s"
    "-w"
    "-X=go.kenn.io/roborev/internal/version.Version=v${version}"
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
