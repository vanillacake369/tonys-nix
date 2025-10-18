# Security configuration: SSH, fail2ban, PAM, Google Authenticator
{pkgs, ...}: {
  # SSH hardening with Google Authenticator 2FA
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    ports = [22];
    allowSFTP = false;
    settings = {
      PasswordAuthentication = false;
      AllowUsers = null;
      UseDns = false;
      X11Forwarding = true;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = true;
      AuthenticationMethods = "publickey,keyboard-interactive";
    };
  };

  # Fail2ban for SSH protection
  services.fail2ban.enable = true;

  # Google MFA on SSH
  security.pam.services = {
    sshd = {
      text = ''
        account required pam_unix.so # unix (order 10900)

        auth required ${pkgs.google-authenticator}/lib/security/pam_google_authenticator.so nullok no_increment_hotp # google_authenticator (order 12500)
        auth sufficient pam_permit.so

        session required pam_env.so conffile=/etc/pam/environment readenv=0 # env (order 10100)
        session required pam_unix.so # unix (order 10200)
        session required pam_loginuid.so # loginuid (order 10300)
        session optional ${pkgs.systemd}/lib/security/pam_systemd.so # systemd (order 12000)
      '';
      googleAuthenticator.enable = true;
    };
  };
}
