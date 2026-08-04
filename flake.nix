{
  description = "mc-rtc-kinova-external-forces: FT-sensor/compliance Kinova stack + forked mc_rtc/RBDyn/TVM, shared by all compliance controllers";

  inputs = {
    mc-rtc-nix.url = "github:mc-rtc/nixpkgs";
    flake-parts.follows = "mc-rtc-nix/flake-parts";
    systems.follows = "mc-rtc-nix/systems";
    mc-rtc-kinova-base.url = "github:mathieu-celerier/mc-rtc-kinova-base";
  };

  outputs =
    inputs:
    let
      # See mc-rtc-kinova-base's flake.nix for the empirically-verified precedence rule:
      # earlier `imports` entries win over later ones for conflicting `overrideAttrs.<name>`
      # keys, with no error raised. This module's own overrides (mc-rtc, mc-kinova, mc-kortex,
      # kinova-mj-description, tvm, mc-joystick-plugin) are what this whole package exists to
      # provide, so wherever this module is imported it must come BEFORE mc-rtc-kinova-base's
      # module in the `imports` list (see below and in downstream controller flakes).
      mcRtcKinovaExternalForcesModule = { ... }: {
        packages = {
          mc-residual-estimation = ./pkgs/mc-residual-estimation.nix;
          minimum-jerk-task = ./pkgs/minimum-jerk-task.nix;
          rokubimini-description = ./pkgs/rokubimini-description.nix;
          bota-driver-description = ./pkgs/bota-driver-description.nix;
          box-demo-controller = ./pkgs/box-demo-controller.nix;
        };

        overrideAttrs = {
          # The one place mc_rtc gets pinned. Both collaborative_peg_in_hole_controller and
          # monodzukuri2024_kinova_demo build against this same branch (user's explicit choice,
          # to stop the two controllers drifting onto different mc_rtc forks).
          mc-rtc =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "mc_rtc";
                rev = "topic/second-order-velocity-damper";
                hash = "sha256-M92prWVVc//Ieibm65xcMj1oGRM69UthOvlWvtXMzSo=";
              };
            };

          # mc_rtc@topic/second-order-velocity-damper is developed against this Tasks branch
          # (jrl-umi3218/Tasks@v1.8.4, currently pinned in mc-rtc/nixpkgs, is missing
          # setExternalTorques and has older constructor signatures for MotionConstr /
          # DamperJointLimitsConstr / MotionSpringConstr).
          tasks =
            { pkgs-final, ... }:
            {
              # This branch predates the newer jrl-cmakemodules fallback logic upstream added in
              # v1.8.4 (find_package/FetchContent if missing) — it unconditionally
              # include()s cmake/base.cmake from a git submodule, so fetchSubmodules is required.
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "Tasks";
                # fetchSubmodules requires a real rev, not a branch name (same ambiguity issue
                # as tvm above).
                rev = "652cf3c7796f7f9cffd9547b637a72e5659c3b46"; # topic/closed-loop-velocity-damper as of 2026-08-04
                fetchSubmodules = true;
                hash = "sha256-/uT867ArLNE3gLFO7qIzGuxUyQYuF7j1dWYQBU6PiwI=";
              };
            };

          # topic/add-genA-bota registers KinovaBotaPegPlate (needed by
          # collaborative_peg_in_hole_controller's config) plus the newer GenA Bota sensor
          # variants — main doesn't have these robot module names at all. It looks up the Bota
          # description data as find_description_package(bota_driver QUIET) rather than
          # rokubimini_description (see bota-driver-description.nix).
          mc-kinova =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "mc_kinova";
                rev = "topic/add-genA-bota";
                hash = "sha256-gRTO2WGK26eYrw7Oh/lEyWis3F6hZGJ4ahfz71P6ntQ=";
              };
              propagatedBuildInputs = [
                pkgs-final.mc-rtc
                pkgs-final.kortex-description
                pkgs-final.robotiq-description
                pkgs-final.bota-driver-description
              ];
            };

          # No override: torqueModeDS is a stale/old topic branch (user's call) — the
          # external-forces stack just uses mc-rtc-kinova-base's main-branch mc-kortex as-is.

          # main-external-forces is the kinova_mj_description branch matching mc-kinova's
          # topic/add-genA-bota — it has the MuJoCo xml for kinova_bota_peg_plate (and all the
          # other GenA/PegPlate variants) that main doesn't.
          kinova-mj-description =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "kinova_mj_description";
                rev = "main-external-forces";
                hash = "sha256-wGmwPxcMPRo6eWxeLlDxN20BiE3uxIe0OSXXcWpfca0=";
              };
            };

          tvm =
            { pkgs-final, ... }:
            {
              # tvm vendors google/benchmark etc as git submodules (3rd-party/CMakeLists.txt
              # add_subdirectory()'s them) — fetchFromGitHub needs fetchSubmodules or those
              # directories come back empty and CMake configure fails.
              src = pkgs-final.fetchFromGitHub {
                owner = "bastien-muraccioli";
                repo = "tvm";
                # fetchSubmodules requires a real rev, not a branch name (a bare branch name is
                # ambiguous once fetchFromGitHub switches to the git-based fetch path needed for
                # submodules, and it errors trying refs/tags/<name> first).
                rev = "62aacd80d49a11e2d56dd3a7dcf712340f7f6b68"; # master as of 2026-08-04
                fetchSubmodules = true;
                hash = "sha256-wAL3wz/s3NoL1CDDDRhEz6JCZH7ygKIZGkcydRyS+eU=";
              };
            };

          # mc-joystick-plugin already exists in mc-rtc/nixpkgs (pinned to isri-aist's repo);
          # monodzukuri needs bastien-muraccioli's fork instead.
          mc-joystick-plugin =
            { pkgs-final, ... }:
            {
              # Same jrl-cmakemodules git-submodule-as-cmake/ pattern as tvm/tasks above.
              src = pkgs-final.fetchFromGitHub {
                owner = "bastien-muraccioli";
                repo = "mc_joystick_plugin";
                rev = "2a9dfb2ae58c3013a182c3c9807bf3c9a46da84f"; # main as of 2026-08-04
                fetchSubmodules = true;
                hash = "sha256-uPd2+gwCr87H8Tfd+aINSxCzhxzTkH3MK1gVt4/VGfU=";
              };
            };
        };
      };
      # This flake's own standalone build: a raw flake-parts flake (NOT going through
      # mkFlakoboros, which only accepts a single flakoboros-config module and can't add
      # arbitrary extra `imports`) that imports mc-rtc-nix's base module, THIS module, and
      # mc-rtc-kinova-base's module — in that order, so this module's overrides win.
      standaloneModules =
        args:
        [
          inputs.mc-rtc-nix.flakeModule
          { flakoboros = mcRtcKinovaExternalForcesModule args; }
          inputs.mc-rtc-kinova-base.flakeModule
        ];
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      args:
      {
        systems = import inputs.systems;
        imports = standaloneModules args;
      }
    )
    // {
      # Re-exported for further downstream flakes (the two controllers): importing this
      # pulls in mc-rtc-kinova-base transitively, so consumers only need this one import
      # alongside mc-rtc-nix's own flakeModule.
      flakeModule = args: {
        imports = [ inputs.mc-rtc-kinova-base.flakeModule ];
        flakoboros = mcRtcKinovaExternalForcesModule args;
      };
    };
}
