{
  lib,
  buildPythonPackage,
  fetchPypi,
  installShellFiles,
  mock,
  openstacksdk,
  pbr,
  python-keystoneclient,
  pythonOlder,
  stestr,
}:

buildPythonPackage rec {
  pname = "python-swiftclient";
  version = "4.6.0";
  format = "setuptools";

  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-1NGFQEE4k/wWrYd5HXQPgj92NDXoIS5o61PWDaJjgjM=";
  };

  # remove duplicate script that will be created by setuptools from the
  # entry_points section of setup.cfg
  postPatch = ''
    sed -i '/^scripts =/d' setup.cfg
    sed -i '/bin\/swift/d' setup.cfg
  '';

  nativeBuildInputs = [ installShellFiles ];

  propagatedBuildInputs = [
    pbr
    python-keystoneclient
  ];

  nativeCheckInputs = [
    mock
    openstacksdk
    stestr
  ];

  postInstall = ''
    installShellCompletion --cmd swift \
      --bash tools/swift.bash_completion
    installManPage doc/manpages/*
  '';

  checkPhase = ''
    stestr run
  '';

  pythonImportsCheck = [ "swiftclient" ];

  meta = with lib; {
    homepage = "https://github.com/openstack/python-swiftclient";
    description = "Python bindings to the OpenStack Object Storage API";
    mainProgram = "swift";
    license = licenses.asl20;
    maintainers = teams.openstack.members;
  };
}
