#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_USER=$(logname)
USER_HOME=$(eval echo "~$ORIGINAL_USER")

# ---------- helpers ----------
need_cmd() { command -v "$1" >/dev/null 2>&1; }

enable_multilib() {
  # Uncomment [multilib] and the following Include line in /etc/pacman.conf
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "No [multilib] section found in /etc/pacman.conf (unexpected). Skipping."
    return 0
  fi

  if grep -q '^\s*#\s*\[multilib\]' /etc/pacman.conf; then
    echo "Enabling multilib in /etc/pacman.conf..."
    sudo sed -i \
      -e 's/^\s*#\s*\[multilib\]/[multilib]/' \
      -e 's/^\s*#\s*Include = \/etc\/pacman\.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' \
      /etc/pacman.conf
  fi
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
    echo "These packages were NOT found in official repos (skipped):"
    printf '  - %s\n' "${missing[@]}"
    echo "If you expected them, they may be AUR packages or named differently on Arch."
  fi
}

install_yay_if_missing() {
  if need_cmd yay; then
    return 0
  fi
  echo "Installing yay (AUR helper)..."
  sudo pacman -S --needed base-devel git

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
}

[[ -d "./.fonts" ]] \
  && sudo -u "$ORIGINAL_USER" mkdir -p "$USER_HOME/.fonts" \
  && sudo -u "$ORIGINAL_USER" cp ./.fonts/* "$USER_HOME/.fonts"

[[ -d "./.icons" ]] \
  && sudo -u "$ORIGINAL_USER" mkdir -p "$USER_HOME/.icons" \
  && sudo -u "$ORIGINAL_USER" cp -r ./.icons/* "$USER_HOME/.icons"

[[ -d "./carPics" ]] \
  && sudo -u "$ORIGINAL_USER" mkdir -p "$USER_HOME/Pictures/carPics" \
  && sudo -u "$ORIGINAL_USER" cp -r ./carPics/* "$USER_HOME/Pictures/carPics"

# Create required user directories in a loop
for dir in ".fonts" ".icons" "Code"; do
  sudo -u "$ORIGINAL_USER" mkdir -p "$USER_HOME/$dir"
done

# Determine real script dir (so $SCRIPT_DIR is absolute)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$USER_HOME/.config"

# Ensure target config directory exists
sudo -u "$ORIGINAL_USER" mkdir -p "$CONFIG_DIR"

# List of config folders you want to link
config_items=(
  bleachbit
  btop
  fastfetch
  hypr
  kitty
  mako
  nvim
  rofi
  ulauncher
  waybar
  wlogout
)

for item in "${config_items[@]}"; do
  SRC="$SCRIPT_DIR/configs/$item"
  DST="$CONFIG_DIR/$item"

  # Skip if source doesn't exist
  if [[ ! -e "$SRC" ]]; then
    echo "⚠ Source not found: $SRC, skipping."
    continue
  fi

  # Remove any existing file, dir, or symlink at DST
  if [[ -e "$DST" || -L "$DST" ]]; then
    sudo -u "$ORIGINAL_USER" rm -rf "$DST"
  fi

  # Create the symlink
  sudo -u "$ORIGINAL_USER" ln -s "$SRC" "$DST"
  echo "✔ Linked $item"
done

# ---------- main ----------
enable_multilib

# Full system upgrade (refresh db + upgrade)
sudo pacman -Syu

# Repo packages (skip anything that isn't in official repos)
repo_pkgs=(
  virt-manager
  virt-viewer
  qemu-full
  libvirt
  dnsmasq
  iptables-nft
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
  fastfetch
  fontconfig
  ttf-fira-code
  ttf-firacode-nerd
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
  amdsmi
  bleachbit
  flatpak
  networkmanager
  noto-fonts-cjk
  cantarell-fonts
  openssh
  vulkan-tools
  mesa-demos
  gamemode
  vi
  neovim
  cronie
  man-db
  man-pages
)

pacman_install_existing_only "${repo_pkgs[@]}"

# Services
sudo systemctl enable --now NetworkManager || true
sudo systemctl enable --now libvirtd
sudo systemctl enable --now docker
sudo systemctl start sshd
sudo systemctl enable sshd
sudo systemctl enable --now cronie.service

# Libvirt default network
sudo virsh net-autostart default || true
sudo virsh net-start default || true

# Groups (re-login required after this)
sudo usermod -aG kvm "$USER" || true
sudo usermod -aG libvirt "$USER" || true
sudo usermod -aG docker "$USER" || true

# AUR packages
install_yay_if_missing

aur_pkgs=(
  brave-bin
  visual-studio-code-bin
  clipman
  wlogout
)

yay -Syu --needed "${aur_pkgs[@]}"

# Flatpak
sudo pacman -S --needed flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

apps=(
  com.belmoussaoui.Authenticator
  org.blender.Blender
  org.gnome.Calendar
  com.discordapp.Discord
  org.mozilla.firefox
  com.github.tchx84.Flatseal
  io.github.shiftey.Desktop
  org.gimp.GIMP
  com.google.Chrome
  org.gnome.gThumb
  fr.handbrake.ghb
  rest.insomnia.Insomnia
  org.gnome.meld
  com.microsoft.Edge
  io.missioncenter.MissionCenter
  com.mongodb.Compass
  org.onlyoffice.desktopeditors
  com.github.PintaProject.Pinta
  net.davidotek.pupgui2
  com.rustdesk.RustDesk
  com.spotify.Client
  com.transmissionbt.Transmission
  org.videolan.VLC
  org.pulseaudio.pavucontrol
  org.gnome.Loupe
  org.gtk.Gtk3theme.Adwaita-dark
  io.github.flattool.Warehouse
  org.flathub.flatpak-external-data-checker
  it.mijorus.gearlever
)

flatpak install -y flathub "${apps[@]}"
