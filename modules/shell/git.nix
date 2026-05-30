{userProfile, ...}: {
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
}
