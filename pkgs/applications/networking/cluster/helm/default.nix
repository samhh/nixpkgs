{ lib, stdenv, buildGoModule, fetchFromGitHub, installShellFiles }:

buildGoModule rec {
  pname = "kubernetes-helm";
  version = "3.9.3";
  gitCommit = "a7c043acb5ff905c261cfdc923a35776ba5e66e4";

  src = fetchFromGitHub {
    owner = "helm";
    repo = "helm";
    rev = "v${version}";
    sha256 = "sha256-fRlHI2g+pSexPzeEqUnow5WTPvNMGnQNWjnllzJ42fY=";
  };
  vendorSha256 = "sha256-ZOY25wgxCdVQafdhBW4Z3aQxOGTs7N3SvSDJ/Fu5psg=";

  subPackages = [ "cmd/helm" ];
  ldflags = [
    "-w"
    "-s"
    "-X helm.sh/helm/v3/internal/version.version=v${version}"
    "-X helm.sh/helm/v3/internal/version.gitCommit=${gitCommit}"
  ];

  preCheck = ''
    # skipping version tests because they require dot git directory
    substituteInPlace cmd/helm/version_test.go \
      --replace "TestVersion" "SkipVersion"
  '' + lib.optionalString stdenv.isLinux ''
    # skipping plugin tests on linux
    substituteInPlace cmd/helm/plugin_test.go \
      --replace "TestPluginDynamicCompletion" "SkipPluginDynamicCompletion" \
      --replace "TestLoadPlugins" "SkipLoadPlugins"
    substituteInPlace cmd/helm/helm_test.go \
      --replace "TestPluginExitCode" "SkipPluginExitCode"
  '';

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    $out/bin/helm completion bash > helm.bash
    $out/bin/helm completion zsh > helm.zsh
    installShellCompletion helm.{bash,zsh}
  '';

  meta = with lib; {
    homepage = "https://github.com/kubernetes/helm";
    description = "A package manager for kubernetes";
    mainProgram = "helm";
    license = licenses.asl20;
    maintainers = with maintainers; [ rlupton20 edude03 saschagrunert Frostman Chili-Man techknowlogick ];
  };
}
