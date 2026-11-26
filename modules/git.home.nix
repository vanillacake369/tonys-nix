{
  lib,
  isDarwin,
  pkgs,
  userProfile,
  ...
}: {
  # Git, GitHub, history-rewrite, and Git-hook executables belong with the
  # declarative Git and LazyGit policy below.
  home.packages = with pkgs; [
    ghalint
    lazygit
    delta
    bfg-repo-cleaner
    lefthook
    git-crypt
    git-filter-repo
    gh
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userProfile.gitUser;
        inherit (userProfile) email;
      };
      credential.helper = "store";
    };
    signing.format = "openpgp";
  };

  # Home Manager resolves this to ~/Library/Application Support/lazygit on
  # Darwin when XDG directories are disabled, which is LazyGit's native path.
  # Keep the renderer declarative instead of relying on an unmanaged config.yml.
  programs.lazygit = {
    enable = true;
    package = null;
    settings.git.diffRenderers = [
      {
        colorArg = "always";
        command = "delta --dark --paging=never --side-by-side --syntax-theme base16-256";
      }
    ];
  };

  # The pre-existing manual config contains the same renderer. Replace it on
  # Darwin so the first Home Manager activation completes the ownership move.
  home.file = lib.optionalAttrs isDarwin {
    "Library/Application Support/lazygit/config.yml".force = true;
  };
}
