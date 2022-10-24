{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  nbformat,
  nbclient,
  ipykernel,
  pandas,
  pytest,
  traitlets,
}:
buildPythonPackage rec {
  pname = "testbook";
  version = "0.4.2";
  format = "pyproject";

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "nteract";
    repo = pname;
    rev = version;
    sha256 = "sha256-qaDgae/5TRpjmjOf7aom7TC5HLHp0PHM/ds47AKtq8U=";
  };

  nativeBuildInputs = [
    nbclient
    nbformat
  ];

  checkInputs = [
    ipykernel
    pandas
    pytest
    traitlets
  ];

  checkPhase = "pytest";

  meta = with lib; {
    description = "testbook is a unit testing framework extension for testing code in Jupyter Notebooks.";
    homepage = "https://testbook.readthedocs.io/";
    license = with licenses; [bsd3];
    maintainers = with maintainers; [djacu];
  };
}
