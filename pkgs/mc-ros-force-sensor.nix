{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  ament-cmake,
  rclcpp,
  geometry-msgs,
  rosPackages,
  mc-rtc,
}:

stdenv.mkDerivation {
  pname = "mc-ros-force-sensor";
  version = "unstable-2026-07-15";

  # topic/new-implementation, NOT main - this is the branch mc-rtc-superbuild pins, and the
  # difference is load-bearing. On main, RosForceSensor::before() does
  # `wrench_sub_.data().value()` unconditionally and writes the result into EEForceSensor every
  # tick. With no publisher on the topic - i.e. any mc_mujoco run, which is not driven by
  # mc_kortex - that writes a *zero* wrench over the one the simulator provides. The F/T channel
  # then reads identically 0, the ExternalForcesEstimator has nothing to fuse against its
  # momentum residual, and the compliance loop in CollabPegInHoleController diverges within
  # ~0.5 s of entering torque control. This branch adds the `if(!data.isValid()) return;` guard.
  #
  # The two branches are divergent, not fast-forward: main carries "Update default config for
  # new bota driver" (2026-06-10), which this branch predates. So this branch's *defaults* are
  # the older ones (reference_frame FT_sensor_force, topic /bus0/ft_sensor0/...). FT_sensor_force
  # is not a body on kinova_bota_peg_plate and bodyPosW() would throw on it, so consumers must
  # override both - see collaborative_peg_in_hole_controller's
  # etc/CollabPegInHoleController/plugins/RosForceSensor.yaml.
  src = fetchFromGitHub {
    owner = "bastien-muraccioli";
    repo = "mc_ros_force_sensor";
    rev = "2b6738805a1150cd44e3bb188baa248e713951f0"; # topic/new-implementation as of 2026-07-15
    hash = "sha256-36y4jSHaxEXRW83BhJYX1h/w0+KiWRraDeNkKjxFfWQ=";
  };

  nativeBuildInputs = [
    cmake
    ament-cmake
  ];
  propagatedBuildInputs = [
    mc-rtc
    rclcpp
    geometry-msgs
    rosPackages.jazzy.std-msgs
  ];

  preConfigure = ''
    export ROS_VERSION=2
  '';

  doCheck = false;

  meta = with lib; {
    description = "RosForceSensor plugin for mc_rtc (feeds a ROS-published wrench topic into an mc_rtc F/T sensor)";
    homepage = "https://github.com/bastien-muraccioli/mc_ros_force_sensor";
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
