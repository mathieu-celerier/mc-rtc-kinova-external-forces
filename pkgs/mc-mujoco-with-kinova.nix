{ pkgs-final, ... }:
let
  # mc_mujoco's own top-level CMakeLists.txt reads this exact version and (absent
  # -DMUJOCO_ROOT_DIR) tries to FetchContent-download the matching official release tarball at
  # configure time, which the sandboxed build can't do — fetch it ourselves and pass it in.
  # nixpkgs' own `mujoco` package (3.8.1 as of this writing) is a newer major/minor than what we
  # want here, so fetch a specific release.
  #
  # 3.6.0, NOT the 3.3.6 in mc_mujoco's own MUJOCO_VERSION file. That file is only a fallback:
  # mc-rtc-superbuild overrides it (extensions/simulation/MuJoCo.cmake:1 sets MUJOCO_VERSION
  # 3.6.0 and passes MUJOCO_ROOT_DIR in), so the working setup builds this same mc_mujoco rev
  # against 3.6.0. Building it against 3.3.6 here made this the only remaining difference in the
  # simulation stack, while a torque-controlled Kinova showed a slowly-growing null-space
  # oscillation in the unlimited joints (0/2/4/6) that the same controller does not exhibit on
  # the superbuild machine. MuJoCo changed integrator defaults and armature handling across 3.x,
  # which is exactly the kind of thing that moves a marginal mode across the stability boundary.
  mujocoVersion = "3.6.0";
  mujocoRelease = pkgs-final.fetchzip {
    url = "https://github.com/google-deepmind/mujoco/releases/download/${mujocoVersion}/mujoco-${mujocoVersion}-linux-x86_64.tar.gz";
    # The tarball wraps everything in a mujoco-3.6.0/ directory — strip exactly that single
    # wrapping level, giving bin/include/lib/... directly at this derivation's root (needed so
    # it lines up with simulate/, merged in below from a separately-fetched source, which
    # fetchFromGitHub already returns unwrapped).
    stripRoot = true;
    hash = "sha256-AjM02Y02b4CAb36CGl5wNOKdrUXjX5yghViACYU9dwc=";
  };
  # The binary release above only has bin/include/lib/doc — no simulate/ dir. mc_mujoco's own
  # src/CMakeLists.txt falls through several MUJOCO_ROOT_DIR-relative locations for the
  # GLFW-based uitools/adapter sources and, absent all of them (as is the case for the binary
  # release), unconditionally needs simulate/{glfw_adapter,glfw_dispatch,platform_ui_adapter}.*
  # from MuJoCo's own *source* repo. Fetch that too and merge both into one MUJOCO_ROOT_DIR.
  mujocoSource = pkgs-final.fetchFromGitHub {
    owner = "google-deepmind";
    repo = "mujoco";
    rev = mujocoVersion;
    hash = "sha256-Gxr8AH9grTjrMTHHOVseLuTC3rNuQEZRWhSvR4HgIc4=";
  };
  mujocoRoot = pkgs-final.runCommand "mujoco-${mujocoVersion}-root" { } ''
    mkdir -p "$out"
    cp -r ${mujocoRelease}/. "$out"
    chmod -R u+w "$out"
    cp -r ${mujocoSource}/simulate "$out/simulate"
  '';

  # kinova_mj_description's own CMakeLists.txt already supports being add_subdirectory()'d
  # in-tree (it does `if(NOT TARGET mc_mujoco) find_package(mc_mujoco REQUIRED) endif()`,
  # skipping find_package once already embedded in mc_mujoco's own build — the same convention
  # this branch's own robots/jvrc_mj_description submodule uses) — copied into robots/ in
  # postPatch below, exactly like a real git submodule would land there.
  kinovaMjDescriptionSrc = pkgs-final.fetchFromGitHub {
    owner = "mathieu-celerier";
    repo = "kinova_mj_description";
    rev = "main-external-forces";
    hash = "sha256-wGmwPxcMPRo6eWxeLlDxN20BiE3uxIe0OSXXcWpfca0=";
  };
in
{
  # Full replacement of mc-rtc/nixpkgs' own mc-mujoco (pinned to a standalone-build fork/PR of
  # rohanpsingh/mc_mujoco) with the user's own fork/branch, which has a materially different
  # build: deps (imgui/implot/ImGuizmo/mc_rtc-imgui/pugixml/glfw) are vendored in-tree rather
  # than taken from nixpkgs packages, and custom robots are registered by dropping a real
  # <name>_mj_description tree into robots/ (add_subdirectory-globbed) rather than via an
  # external MC_MUJOCO_SHARE_DESTINATION-populated derivation the way the pinned fork works — so
  # the usual mc-mujoco-robots .override() mechanism doesn't apply here; kinova_mj_description is
  # embedded directly below instead.
  src = pkgs-final.fetchFromGitHub {
    owner = "mathieu-celerier";
    repo = "mc_mujoco";
    rev = "3eb766016b6f276eed2e900af89a4c08de8da4c6"; # my_branch as of 2026-08-04
    fetchSubmodules = true; # robots/jvrc_mj_description, ext/mc_rtc-imgui, examples/grasp-fsm
    hash = "sha256-ZCJ2BXv/ktY0g1BDtsQbSLZmbj/nBPeBoN5lLRvlkdM=";
  };

  postPatch = ''
    cp -r ${kinovaMjDescriptionSrc} robots/kinova_mj_description
    chmod -R u+w robots/kinova_mj_description
  '';

  dontBuild = true; # installPhase's `cmake --build . --target install` builds everything anyway

  nativeBuildInputs = with pkgs-final; [
    cmake
    pkg-config
    makeWrapper
  ];
  buildInputs = with pkgs-final; [
    cli11
    glew
    libGL
    libGLU
    libxrandr
    libxinerama
    libxcursor
    libx11
    libxi
    libxext
  ];
  propagatedBuildInputs = [ pkgs-final.mc-rtc ];

  cmakeFlags = [
    "-DMUJOCO_ROOT_DIR=${mujocoRoot}"
    "-DBUILD_EXAMPLES=OFF"
  ];

  # See https://github.com/glfw/glfw/issues/2839
  postInstall = ''
    wrapProgram $out/bin/mc_mujoco \
      --set XDG_SESSION_TYPE "" \
      --set WAYLAND_DISPLAY ""
  '';

  doCheck = false;

  meta = with pkgs-final.lib; {
    mainProgram = "mc_mujoco";
    description = "MuJoCo interface for mc_rtc (mathieu-celerier's fork, with kinova_mj_description embedded as a robot)";
    homepage = "https://github.com/mathieu-celerier/mc_mujoco";
    license = licenses.bsd2;
    platforms = platforms.linux;
  };
}
