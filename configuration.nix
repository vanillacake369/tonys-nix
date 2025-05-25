# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "kvm.enable_virt_at_load=0" ];
    blacklistedKernelModules = [ "kvm" "kvm_intel" "kvm_amd" ];
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
      ibus.engines = with pkgs.ibus-engines; [ hangul ];
    };
  };


  services = {
    nfs.server.enable = true;
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
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
      ports = [ 22 ];
      allowSFTP = false;
      settings = {
        PasswordAuthentication = false;
        AllowUsers = null;
        UseDns = false;
        X11Forwarding = false;
        PermitRootLogin = "prohibit-password";
        KbdInteractiveAuthentication = false;
      };
    };
    fail2ban.enable = true;
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
          "vboxusers"
        ];
        packages = with pkgs; [
        ];
      };
    };
  };
 
  # Allow experimental-features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
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
  
  environment.shells = with pkgs; [ zsh ];
  environment.systemPackages = with pkgs; [
    # Korean Input
    ibus
    ibus-engines.hangul
    noto-fonts-cjk-sans
    # Container
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
  ];

  # Enable common container config files in /etc/containers
  virtualisation = {
    containers.enable = true;
    virtualbox.host.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Initiate minikube systemd service
  # ToDo : How can I move this to home-manager ??
  systemd.user.services.minikube = {
    enable = true;
    description = "Init Minikube Cluster";
    wantedBy = [ "default.target" ];
    after = [ "podman.socket" ];
    requires = [ "podman.socket" ];
    serviceConfig = {
      Type = "simple";
      Environment = "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:/run/wrappers/bin";
      ExecStart = "${pkgs.minikube}/bin/minikube start --driver=podman";
      ExecStop = "${pkgs.minikube}/bin/minikube stop";
      RemainAfterExit = true;
    };
  };

  # Firewall of inbound traffic
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Add firewall exception for libvirt provider when using NFSv4
      interfaces."virbr1" = {
        allowedTCPPorts = [ 2049 ];
        allowedUDPPorts = [ 2049 ];
      };
      # Allow ssh port
      allowedTCPPorts = [
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
