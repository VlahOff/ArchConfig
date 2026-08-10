#!/usr/bin/env bash
set -Eeuo pipefail

report_error() {
  local exit_code="$1"
  local line_number="$2"
  local failed_command="$3"

  printf '❌ Error: command failed with exit code %s at line %s: %s\n' \
    "$exit_code" "$line_number" "$failed_command" >&2
}

trap 'report_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

# Run this script as your normal user, not with sudo.
# The script uses sudo only where needed.
if [[ "$EUID" -eq 0 ]]; then
  echo "❌ Run this script as your normal user, not with sudo."
  echo "Example: ./install.sh"
  exit 1
fi

ORIGINAL_USER="$USER"
USER_HOME="$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  echo "❌ Could not determine home directory for user: $ORIGINAL_USER"
  exit 1
fi

# ---------- helpers ----------
need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

prompt_yes_no() {
  local prompt_message="$1"
  local response

  while true; do
    read -rp "$prompt_message (y/n): " response

    case "$response" in
      [Yy])
        return 0
        ;;
      [Nn])
        return 1
        ;;
      *)
        echo "Please answer y or n."
        ;;
    esac
  done
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"

  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    cp -a "$src"/. "$dst"/
  fi
}

enable_multilib() {
  if pacman-conf --repo multilib Server 2>/dev/null | grep -q .; then
    echo "multilib already enabled."
    return 0
  fi

  if ! grep -Eq '^[[:space:]]*#?[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    echo "❌ No [multilib] section found in /etc/pacman.conf."
    return 1
  fi

  echo "Enabling multilib..."
  sudo sed -Ei \
    '/^[[:space:]]*#?[[:space:]]*\[multilib\][[:space:]]*$/,/^[[:space:]]*#?[[:space:]]*\[[^]]+\][[:space:]]*$/ {
      s/^[[:space:]]*#[[:space:]]*(\[multilib\][[:space:]]*)$/\1/
      s|^[[:space:]]*#[[:space:]]*(Include[[:space:]]*=[[:space:]]*/etc/pacman.d/mirrorlist[[:space:]]*)$|\1|
    }' /etc/pacman.conf

  if ! pacman-conf --repo multilib Server 2>/dev/null | grep -q .; then
    echo "❌ multilib has no configured Pacman servers after editing /etc/pacman.conf."
    return 1
  fi

  echo "multilib enabled."
}

pacman_install_existing_only() {
  local -a pkgs=("$@")
  local -a install=()
  local -a missing=()

  for p in "${pkgs[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then
      install+=("$p")
    else
      missing+=("$p")
    fi
  done

  if ((${#install[@]})); then
    sudo pacman -S --needed "${install[@]}"
  fi

  if ((${#missing[@]})); then
    echo "These packages were NOT found in official repos and were skipped:"
    printf '  - %s\n' "${missing[@]}"
    echo "They may be AUR packages or named differently on Arch."
  fi
}

pacman_remove_installed_only() {
  local -a pkgs=("$@")
  local -a remove=()

  for p in "${pkgs[@]}"; do
    if pacman -Q "$p" >/dev/null 2>&1; then
      remove+=("$p")
    fi
  done

  if ((${#remove[@]})); then
    sudo pacman -Rs "${remove[@]}"
  else
    echo "No listed packages are installed. Nothing to remove."
  fi
}

install_yay_if_missing() {
  if need_cmd yay; then
    return 0
  fi

  echo "Installing yay AUR helper..."
  sudo pacman -S --needed base-devel git

  local tmpdir
  tmpdir="$(mktemp -d)"

  (
    trap 'rm -rf -- "$tmpdir"' EXIT

    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si
  )
}

install_user_files() {
  local config_dir="$USER_HOME/.config"
  local config_src_dir
  local item src dst
  local -a config_items=(
    btop
    fastfetch
    hypr
    kitty
    mako
    nvim
    rofi
    waybar
    wlogout
  )

  copy_dir_contents "$SCRIPT_DIR/.fonts" "$USER_HOME/.fonts"
  copy_dir_contents "$SCRIPT_DIR/.icons" "$USER_HOME/.icons"

  for item in ".fonts" ".icons" "Code"; do
    mkdir -p "$USER_HOME/$item"
  done

  mkdir -p "$config_dir"

  if prompt_yes_no "Do you want to install PC or Laptop configs (y=PC | n=Laptop)"; then
    echo "Linking PC configs..."
    config_src_dir="$SCRIPT_DIR/configs"
  else
    echo "Linking laptop configs..."
    config_src_dir="$SCRIPT_DIR/configs-laptop"
  fi

  if [[ ! -d "$config_src_dir" ]]; then
    echo "❌ Config source directory not found: $config_src_dir"
    return 1
  fi

  for item in "${config_items[@]}"; do
    src="$config_src_dir/$item"
    dst="$config_dir/$item"

    if [[ ! -e "$src" ]]; then
      echo "⚠ Source not found: $src, skipping."
      continue
    fi

    echo "Replacing $dst with symlink to $src"

    if [[ -e "$dst" || -L "$dst" ]]; then
      rm -rf -- "$dst"
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
      echo "❌ Failed to remove existing path: $dst"
      return 1
    fi

    # -T prevents linking inside an existing directory
    ln -sT -- "$src" "$dst"
    echo "✔ Linked $item"
  done
}

install_kernel_headers() {
  local kernel
  local -a installed_kernel_headers=()
  local -a supported_kernels=(linux linux-lts linux-zen linux-hardened)

  for kernel in "${supported_kernels[@]}"; do
    if pacman -Q "$kernel" >/dev/null 2>&1; then
      installed_kernel_headers+=("${kernel}-headers")
    fi
  done

  if ((${#installed_kernel_headers[@]})); then
    echo "Installing headers for detected kernels: ${installed_kernel_headers[*]}"
    pacman_install_existing_only "${installed_kernel_headers[@]}"
  else
    echo "⚠ No supported installed kernel detected; skipping kernel headers."
  fi
}

# ---------- main ----------
enable_multilib

# Refresh package databases and complete the full upgrade as one operation.
sudo pacman -Syu

remove_pkgs=(
  snapshot
  gnome-connections
  gnome-maps
  decibels
  gnome-contacts
  showtime
  gnome-music
  dolphin
  gnome-weather
  epiphany
  gnome-software
  gnome-calendar
  loupe
)

pacman_remove_installed_only "${remove_pkgs[@]}"

# Repo packages
repo_pkgs=(
  ufw
  virt-manager
  virt-viewer
  qemu-full
  libvirt
  dnsmasq
  iptables
  edk2-ovmf
  swtpm
  docker
  base-devel
  git
  curl
  ncdu
  btop
  htop
  tldr
  zsh
  sqlite
  util-linux
  gnome-tweaks
  gparted
  file-roller
  network-manager-applet
  blueman
  lxappearance
  mako
  waybar
  rofi
  xdg-desktop-portal-hyprland
  hyprpaper
  hypridle
  hyprlock
  hyprpolkitagent
  hyprpicker
  solaar
  gnome-themes-extra
  powertop
  brightnessctl
  fastfetch
  fontconfig
  ttf-fira-code
  ttf-firacode-nerd
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
  woff2-font-awesome
  otf-font-awesome
  grim
  hplip
  mangohud
  goverlay
  gamescope
  steam
  github-cli
  timeshift
  bleachbit
  flatpak
  networkmanager
  noto-fonts-cjk
  cantarell-fonts
  openssh
  vulkan-tools
  mesa-demos
  gamemode
  neovim
  cronie
  man-db
  man-pages
  slurp
  tesseract
  wl-clipboard
  tesseract-data-bul
  nemo
  clamav
  cups
  jq
  python-pip
  reflector
  ripgrep
  wine
  wlr-randr
)

amd_monitoring_pkgs=(
  amdsmi
  rocm-smi-lib
)

pacman_install_existing_only "${repo_pkgs[@]}"
install_kernel_headers

if prompt_yes_no "Do you want to install AMD GPU monitoring tools"; then
  echo "Installing AMD GPU monitoring tools..."
  pacman_install_existing_only "${amd_monitoring_pkgs[@]}"
else
  echo "Skipping AMD GPU monitoring tools."
fi

# ---------- services ----------
sudo systemctl enable --now NetworkManager || true
sudo systemctl enable --now libvirtd
sudo systemctl enable --now docker
sudo systemctl enable --now cronie.service
sudo systemctl enable --now cups.socket
sudo systemctl enable --now reflector.timer

ssh_enabled=0
if prompt_yes_no "Do you want to enable the SSH server"; then
  sudo systemctl enable --now sshd
  ssh_enabled=1
else
  echo "Leaving the SSH server disabled."
fi

sudo systemctl start clamav-freshclam-once.service
sudo systemctl enable --now clamav-freshclam-once.timer

# Libvirt default network
sudo virsh net-autostart default || true
sudo virsh net-start default || true

# Groups - log out and back in after this
sudo usermod -aG kvm "$ORIGINAL_USER" || true
sudo usermod -aG libvirt "$ORIGINAL_USER" || true
sudo usermod -aG docker "$ORIGINAL_USER" || true

# Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
if ((ssh_enabled)); then
  sudo ufw limit 22/tcp
fi
sudo ufw enable
sudo systemctl enable --now ufw.service

# ---------- AUR packages ----------
install_yay_if_missing

aur_pkgs=(
  brave-bin
  visual-studio-code-bin
  clipman
  wlogout
)

yay -Syu --needed "${aur_pkgs[@]}"

# ---------- Flatpak ----------
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

apps=(
  com.github.tchx84.Flatseal
  io.github.flattool.Warehouse
  it.mijorus.gearlever
  org.flathub.flatpak-external-data-checker
  org.gnome.Calendar
  org.gnome.Loupe
  org.gnome.meld
  org.gtk.Gtk3theme.Adwaita-dark
  org.mozilla.firefox
  org.pulseaudio.pavucontrol
  org.videolan.VLC
)

apps2=(
  com.anydesk.Anydesk
  com.rustdesk.RustDesk
  com.discordapp.Discord
  com.github.PintaProject.Pinta
  com.google.Chrome
  com.microsoft.Edge
  com.mongodb.Compass
  com.spotify.Client
  com.transmissionbt.Transmission
  com.viber.Viber
  eu.codepoems.xl-converter
  fr.handbrake.ghb
  io.github.shiftey.Desktop
  io.missioncenter.MissionCenter
  net.davidotek.pupgui2
  org.blender.Blender
  org.gimp.GIMP
  org.gnome.gThumb
  org.onlyoffice.desktopeditors
  rest.insomnia.Insomnia
  org.telegram.desktop
  app.zen_browser.zen
)

if prompt_yes_no "Do you want to install full or minimal flatpaks (y=full | n=minimal)"; then
  echo "Installing full Flatpaks..."
  flatpak install -y flathub "${apps[@]}" "${apps2[@]}"
else
  echo "Installing minimal Flatpaks..."
  flatpak install -y flathub "${apps[@]}"
fi

# Install user files only after all package phases have succeeded.
install_user_files

echo "Done."
echo "Log out and back in, or reboot, so group changes take effect."
