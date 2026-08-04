addAmentDescriptionPrefixPath() {
  addToSearchPath AMENT_PREFIX_PATH "$1"
}
addEnvHooks "$targetOffset" addAmentDescriptionPrefixPath
