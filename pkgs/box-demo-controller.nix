{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  jrl-cmakemodulesv2,
  mc-rtc,
  mkMcRtcController,
}:

# BoxDemoController: a separate full mc_rtc FSM controller that
# monodzukuri2024_kinova_demo@rss2025_new_implementation depends on via
# find_package(BoxDemoController REQUIRED) (for the "joypad box demo mode" it can switch into,
# using BoxDemoController's exported PACKAGE_EXTRA_MACROS pointing at its installed FSM states).
mkMcRtcController {
  pname = "BoxDemoController";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "mathieu-celerier";
    repo = "box-carying-demo";
    # Same jrl-cmakemodules git-submodule-as-cmake/ pattern as tvm/Tasks/mc-joystick-plugin —
    # fetchSubmodules requires a real rev, not a branch name.
    rev = "c1862599c78a902d766d9f3fe88d3e2763dac1b7"; # main as of 2026-08-04
    fetchSubmodules = true;
    hash = "sha256-z9Ny4yBa4uhOWl94ERiSAdKwQVjEV5OY9z8oauMqtZQ=";
  };

  # Upstream accidentally committed a build/ directory, which collides with cmake's own mkdir.
  postPatch = ''
    rm -rf build
  '';

  nativeBuildInputs = [ cmake ];
  buildInputs = [ jrl-cmakemodulesv2 ];
  propagatedBuildInputs = [ mc-rtc ];

  doCheck = false;

  passthru.mc-rtc = {
    controller = {
      Enabled = "BoxDemoController";
    };
  };

  meta = with lib; {
    description = "Box-carrying compliance demo controller for mc_rtc (joypad-triggered mode used by monodzukuri2024_kinova_demo)";
    homepage = "https://github.com/mathieu-celerier/box-carying-demo";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
