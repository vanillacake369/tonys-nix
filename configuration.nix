# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: let
  userHome = config.users.users.limjihoon.home;
in {
  imports = 
    # Include the results of the hardware scan.
    # NOTE: hardware-configuration.nix is stored in /etc/nixos/ (outside flake)
    # Generate it on each new machine with: sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
    # Only import if the file exists (for actual NixOS systems)
    lib.optionals (builtins.pathExists /etc/nixos/hardware-configuration.nix) [
      /etc/nixos/hardware-configuration.nix
    ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = ["kvm.enable_virt_at_load=0"];
    blacklistedKernelModules = [
      "kvm"
      "kvm_intel"
      "kvm_amd"
    ];
  };

  # Set your time zone.
  time.timeZone = "Asia/Seoul";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ko_KR.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "ko_KR.UTF-8";
      LC_IDENTIFICATION = "ko_KR.UTF-8";
      LC_MEASUREMENT = "ko_KR.UTF-8";
      LC_MONETARY = "ko_KR.UTF-8";
      LC_NAME = "ko_KR.UTF-8";
      LC_NUMERIC = "ko_KR.UTF-8";
      LC_PAPER = "ko_KR.UTF-8";
      LC_TELEPHONE = "ko_KR.UTF-8";
      LC_TIME = "ko_KR.UTF-8";
    };
    inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [hangul];
    };
  };

  # NFS / X-SERVER / PIPEWIRE / OPENSSH
  services = {
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "ignore";
          HandlePowerKey = "ignore";
          HandleSuspendKey = "ignore";
          HandleHibernateKey = "ignore";
          HandlePowerKeyLongPress = "ignore";
          IdleAction = "ignore";
          IdleActionSec = "0";
        };
      };
    };
    # SSD optimization: limit systemd journal size and rotation
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=50M
      SystemMaxFiles=10
      MaxRetentionSec=1month
    '';
    nfs.server.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      config = lib.mkAfter ''
        Section "ServerFlags"
          Option "DontVTSwitch" "True"
        EndSection
      '';
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
        clickMethod = "buttonareas";
        middleEmulation = true;
        accelSpeed = "0.3";
        additionalOptions = ''
          Option "PalmDetection" "on"
          Option "TappingButtonMap" "lmr"
          Option "ScrollPixelDistance" "50"
        '';
      };
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    openssh = {
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
    fail2ban.enable = true;
    openvpn.servers.hamaVPN = {
      autoStart = false;
      config = ''
        config ${userHome}/my-nixos/openvpn/lonelynight1026.ovpn
      '';
      updateResolvConf = true;
    };
  };
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

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

  # Nix configuration optimized for performance and SSD longevity
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    # Performance optimizations
    auto-optimise-store = true;  # Enable store deduplication for better performance
    max-jobs = "auto";          # Use all available cores (8 cores detected)
    cores = 0;                  # Use all available cores per job
    # Binary caches to reduce local builds (removed duplicate cache.nixos.org)
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # Optimized garbage collection for better performance and SSD longevity
  nix.gc = {
    automatic = true;
    dates = "daily";                     # More frequent cleanup for better performance
    options = "--delete-older-than 7d";  # Shorter retention for smaller store size
  };

  programs.zsh.enable = true;
  programs.java = {
    enable = true;
    package = pkgs.zulu17;
  };
  programs.firefox.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  
  # Enable nix-ld for running dynamically linked executables
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Basic system libraries
      stdenv.cc.cc
      zlib
      openssl
      curl
      
      # Python-related libraries (for claude-monitor and other Python tools)
      libffi
      glib
      
      # CLI tool dependencies
      ncurses
      readline
    ];
  };

  environment.shells = with pkgs; [zsh];
  environment.systemPackages = with pkgs; [
    # Korean Input
    ibus
    ibus-engines.hangul
    noto-fonts-cjk-sans
    # CPU Usage with cutty catty
    gnomeExtensions.runcat
    # SSD optimization: firmware updates
    fwupd
  ];

  # Enable fwupd service for firmware updates
  services.fwupd.enable = true;

  # Enable common container config files in /etc/containers
  virtualisation = {
    containers = {
      enable = true;
      registries = {
        search = ["docker.io"]; # could be replaced with 'quay.io'
        insecure = [];
        block = [];
      };
    };
    # VirtualBox disabled due to build failures with VirtualBox 7.2.0 and libcurl compatibility
    # Using Podman as container runtime instead
    # virtualbox.host.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Disable systemd sleep targets to prevent automatic suspend/hibernate
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Power management - disable automatic suspend/hibernate
  powerManagement = {
    enable = false;
    powertop.enable = false;
  };

  # Firewall of inbound traffic
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = lib.mkDefault true;  # Allow override for image formats that disable firewall
      # Add firewall exception for libvirt provider when using NFSv4
      interfaces."virbr1" = {
        allowedTCPPorts = [2049];
        allowedUDPPorts = [2049];
      };
      # Allow ports
      allowedTCPPorts = [
        # SSH
        22
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
