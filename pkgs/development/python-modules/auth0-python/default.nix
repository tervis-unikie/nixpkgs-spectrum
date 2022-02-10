{ lib
, buildPythonPackage
, fetchPypi
, mock
, pyjwt
, pytestCheckHook
, pythonOlder
, requests
}:

buildPythonPackage rec {
  pname = "auth0-python";
  version = "3.22.0";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-05yJbF6eXz+vJx+plY5gqzRRYL2SjDnF7gSfX6WIS4E=";
  };

  propagatedBuildInputs = [
    requests
    pyjwt
  ];

  checkInputs = [
    mock
    pytestCheckHook
  ];

  disabledTests = [
    # tries to ping websites (e.g. google.com)
    "can_timeout"
    "test_options_are_created_by_default"
    "test_options_are_used_and_override"
  ];

  pythonImportsCheck = [
    "auth0"
  ];

  meta = with lib; {
    description = "Auth0 Python SDK";
    homepage = "https://github.com/auth0/auth0-python";
    license = licenses.mit;
    maintainers = with maintainers; [ costrouc ];
  };
}
