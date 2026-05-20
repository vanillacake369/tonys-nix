{userProfile, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userProfile.gitUser;
        email = userProfile.email;
      };
      credential.helper = "store";
    };
    signing.format = "openpgp";
  };
}
