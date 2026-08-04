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
  version = "unstable-2026-08-04";

  src = fetchFromGitHub {
    owner = "bastien-muraccioli";
    repo = "mc_ros_force_sensor";
    rev = "35af01ba2fdf7ba0c428d2947a09c336f8c441b0"; # main as of 2026-08-04
    hash = "sha256-KufUDzE0rncbyFRv1gZFDih1HqDiGYm1pmUWTnsTMPU=";
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
