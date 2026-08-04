{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  jrl-cmakemodulesv2,
  mc-rtc,
}:

stdenv.mkDerivation {
  pname = "minimum-jerk-task";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "mathieu-celerier";
    repo = "MinimumJerkTask";
    # Same jrl-cmakemodules git-submodule-as-cmake/ pattern as tvm/tasks/mc-joystick-plugin —
    # fetchSubmodules requires a real rev, not a branch name.
    rev = "eb5573e0e0604a04cc2adf7dda9f8d6c6d37474f"; # main as of 2026-08-04
    fetchSubmodules = true;
    hash = "sha256-n2gYtqNWlyuP6OIFuFVBXjrXusZ2p3lRQ7ccI7l/AFU=";
  };

  buildInputs = [ jrl-cmakemodulesv2 ];
  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [ mc-rtc ];

  doCheck = false;

  meta = with lib; {
    description = "MinimumJerkTask for mc_rtc";
    homepage = "https://github.com/mathieu-celerier/MinimumJerkTask";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
