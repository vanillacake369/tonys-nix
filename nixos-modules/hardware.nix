# Hardware-related services: audio, printing, input devices
{pkgs, ...}: {
  # Libinput configuration (basic enablement)
  # Note: Touchpad settings are managed via GNOME dconf (see modules/gnome-settings.nix)
  services.libinput.enable = true;

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
