{...}: {
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultOptions = [
      "--info=inline"
      "--border=rounded"
      "--margin=1"
      "--padding=1"
    ];
  };
}
