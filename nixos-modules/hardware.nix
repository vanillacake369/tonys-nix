# Hardware-related services: audio, printing, input devices
{pkgs, ...}: {
  # Touchpad and input device configuration
  services.libinput = {
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

  # Printing support
  services.printing.enable = true;

  # Audio with pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable sound with pipewire
  security.rtkit.enable = true;

  # System packages for hardware support
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
}
