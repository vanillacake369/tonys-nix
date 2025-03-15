{ ... }: {
  programs.git = {
    enable = true;
    userName = "Lim Jihoon";
    userEmail = "your-email@example.com";
  };

  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.theme = "agnoster";
    ohMyZsh.plugins = [ "git" "zsh-autosuggestions" "zsh-syntax-highlighting" ];
  };
}

