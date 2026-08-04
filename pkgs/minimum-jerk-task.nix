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
    rev = "main";
    hash = "sha256-z2g0qb31Q1XiY7ruoVpND2dfG/RLJPZXZFIJGI8KAqg=";
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
