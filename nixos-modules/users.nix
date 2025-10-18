# User accounts and shell configuration
{pkgs, ...}: {
  # Define a user account. Don't forget to set a password with 'passwd'.
  users = {
    users = {
      limjihoon = {
        shell = pkgs.zsh;
        isNormalUser = true;
        description = "Limjihoon";
        extraGroups = [
          "networkmanager"
          "wheel"
          "input"
        ];
        packages = with pkgs; [
        ];
      };
    };
  };

  # Shell configuration
  programs.zsh.enable = true;
  environment.shells = with pkgs; [zsh];
}
