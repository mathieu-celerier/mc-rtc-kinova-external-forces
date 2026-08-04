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

          mc-kinova =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "mc_kinova";
                rev = "topic/bota_ft_sensor";
                hash = "sha256-bd/vlwuU8imEkZFCpau9zCm87CjK+4XAajk3eruJyNk=";
              };
            };

          mc-kortex =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "mc_kortex";
                rev = "torqueModeDS";
                hash = "sha256-jAV61GdZKx9i9f2qHJznif44nYDmwbzRCFeTqw+n+9g=";
              };
            };

          kinova-mj-description =
            { pkgs-final, ... }:
            {
              src = pkgs-final.fetchFromGitHub {
                owner = "mathieu-celerier";
                repo = "kinova_mj_description";
                rev = "bota_ft_sensor";
                hash = "sha256-Ig+JlYapZ15SWm3q71T/jA7jO3tqyEBA3lqXUK9cMUo=";
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
              src = pkgs-final.fetchFromGitHub {
                owner = "bastien-muraccioli";
                repo = "mc_joystick_plugin";
                rev = "main";
                hash = "sha256-MIPU0M17ZM3o/2dKnnVMqr2hF0hUgjlB10Gks3qSewc=";
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
