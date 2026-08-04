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

  # jrl-cmakemodules' install macro (as vendored by this repo's cmake/ submodule) bakes
  # CMAKE_INSTALL_INCLUDEDIR straight into the exported target's INTERFACE_INCLUDE_DIRECTORIES
  # without wrapping it in $<INSTALL_INTERFACE:...>. nixpkgs' cmake setup hook normally passes
  # that as an absolute path (e.g. $out/include), which then gets double-concatenated with
  # ${_IMPORT_PREFIX} by consumers (CMake Error: "Imported target ... includes non-existent
  # path ${_IMPORT_PREFIX}/$out/include"). Forcing it relative here avoids the double-prefix.
  cmakeFlags = [ "-DCMAKE_INSTALL_INCLUDEDIR=include" ];

  doCheck = false;

  meta = with lib; {
    description = "MinimumJerkTask for mc_rtc";
    homepage = "https://github.com/mathieu-celerier/MinimumJerkTask";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
