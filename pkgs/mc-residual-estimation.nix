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
    rev = "topic/HumanoidResidual_new_implementation";
    hash = "sha256-rzWtNE4mJ73dX+gTR9hdQDTmHlLMMl+8nwJ7KwbA/Nk=";
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
