{
  username = "limjihoon";
  email = "lonelynight1026@gmail.com";
  gitUser = "limjihoon";
  stateVersion = "23.11";

  # WSL-specific paths
  windowsHome = "/mnt/c/Users/limjihoon";

  jetbrains = {
    # Directory name globs (settings-mac, settings-wsl)
    ides = [
      "IntelliJIdea"
      "GoLand"
      "DataGrip"
      "WebStorm"
      "PhpStorm"
      "PyCharm"
      "RubyMine"
      "CLion"
      "Rider"
      "AndroidStudio"
    ];
    # macOS bundle IDs (keybinds workspace routing)
    bundleIds = [
      "com.jetbrains.intellij"
      "com.jetbrains.goland"
      "com.jetbrains.datagrip"
    ];
  };

  browsers = {
    bundleIds = [
      "^com\\.google\\.Chrome$"
      "^com\\.brave\\.Browser$"
    ];
  };
}
