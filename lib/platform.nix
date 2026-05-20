# Platform feature profile (Toggle Router pattern)
# Centralizes platform detection logic that was scattered across modules.
{
  isDarwin,
  isLinux,
  isWsl,
  isNixOs,
}: {
  type =
    if isDarwin
    then "darwin"
    else if isNixOs
    then "nixos"
    else if isWsl
    then "wsl"
    else "linux";

  features = {
    gui = isDarwin || isNixOs || (isLinux && !isWsl);
    systemd = isLinux || isNixOs;
    launchd = isDarwin;
    wsl = isWsl;
    tiling = isDarwin;
    hyprland = isNixOs;
  };
}
