# Overlay to remove GUI dependencies from multipass for WSL environments
# This recreates the multipass symlinkJoin without multipass-gui
final: prev: {
  multipass = final.symlinkJoin {
    inherit (prev.multipass) version;
    pname = "multipass";

    # Only include multipassd, exclude multipass-gui
    paths = builtins.filter
      (path: !(final.lib.hasInfix "multipass-gui" (toString path)))
      prev.multipass.paths;

    # Preserve passthru and metadata
    passthru = prev.multipass.passthru or {};

    meta = (prev.multipass.meta or {}) // {
      description = "Ubuntu VMs on demand for any workstation (headless - no GUI)";
    };
  };
}
