{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  mc-rtc,
}:

stdenv.mkDerivation {
  pname = "mc-residual-estimation";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "mathieu-celerier";
    repo = "mc_residual_estimation";
    rev = "main";
    hash = "sha256-w5Mxd1MjOxvah3JUxV7yk7rDqKj/od3KvpWdMjFT8og=";
  };

  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [ mc-rtc ];

  doCheck = false;

  meta = with lib; {
    description = "ExternalForcesEstimator plugin for mc_rtc (external force/torque residual estimation)";
    homepage = "https://github.com/mathieu-celerier/mc_residual_estimation";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
