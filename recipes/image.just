# Build or inspect image outputs. Actions: list, build, build-arch, build-all, show.
image action="list" arg="" arch="":
    #!/usr/bin/env bash
    case {{ quote(action) }} in
      list)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image list" >&2; exit 2; }
        just list-image-formats
        ;;
      build)
        [[ -n {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image build <format>" >&2; exit 2; }
        just build-image {{ quote(arg) }}
        ;;
      build-arch)
        [[ -n {{ quote(arg) }} && -n {{ quote(arch) }} ]] || { echo "[x] Usage: just image build-arch <format> <arch>" >&2; exit 2; }
        just build-image-arch {{ quote(arg) }} {{ quote(arch) }}
        ;;
      build-all)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image build-all" >&2; exit 2; }
        just build-images
        ;;
      show)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image show" >&2; exit 2; }
        just show-images
        ;;
      *) echo "[x] Expected: just image {list|build|build-arch|build-all|show}" >&2; exit 2 ;;
    esac

# List supported image outputs.
[private]
list-image-formats:
    #!/usr/bin/env bash
    echo "Available image formats for {{ SYSTEM_ARCH }}:"
    echo
    echo "Format        Description"
    echo "----------    -----------"
    echo "iso           Bootable ISO image"
    echo "virtualbox    VirtualBox OVA image"
    echo "vmware        VMware VMDK image"
    echo "qcow          QEMU qcow image"
    echo
    echo "Usage: just build-image <format>"
    echo "Note: For containers, use official NixOS Docker images instead."

# Build one image format for the current architecture.
[private]
build-image format:
    #!/usr/bin/env bash
    echo "[!] Building {{ format }} image for {{ SYSTEM_ARCH }}"
    nix build .#"{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build one image format for a specific architecture.
[private]
build-image-arch format arch:
    echo "[!] Building {{ format }} image for {{ arch }}"
    nix build .#packages."{{ arch }}"."{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build all supported image formats for the current architecture.
[private]
build-images:
    #!/usr/bin/env bash
    failed=()
    for format in iso virtualbox vmware qcow; do
      echo "[!] Building $format"
      if nix build ".#$format"; then
    echo "[✓] $format built successfully"
      else
    echo "[✗] $format build failed"
    failed+=("$format")
      fi
      echo
    done

    if [[ "${#failed[@]}" -gt 0 ]]; then
      echo "[✗] Failed formats: ${failed[*]}"
      exit 1
    fi

    echo "[✓] All image formats built successfully"

# Show local build artifacts produced by image builds.
[private]
show-images:
    #!/usr/bin/env bash
    echo "Built images in ./result*:"
    ls -lh result* 2>/dev/null | awk '{print $9, $5}' | column -t || echo "No images found. Run 'just build-image <format>' first."
