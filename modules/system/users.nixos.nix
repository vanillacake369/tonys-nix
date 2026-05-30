# User accounts and shell configuration
{pkgs, ...}: {
  # Define a user account. Don't forget to set a password with 'passwd'.
  users = {
    users = {
      limjihoon = {
        shell = pkgs.fish;
        isNormalUser = true;
        description = "Limjihoon";
        extraGroups = [
          "networkmanager"
          "wheel"
          "input"
        ];
      };
    };
  };

  # Shell configuration
  programs.fish.enable = true;
  environment.shells = with pkgs; [fish];
}
