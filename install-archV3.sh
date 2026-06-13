#!/usr/bin/env bash
set -euo pipefail

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
  if grep -q '^[[:space:]]*\[multilib\]' /etc/pacman.conf; then
    echo "multilib already appears to be enabled."
    return 0
  fi

  if grep -q '^[[:space:]]*#[[:space:]]*\[multilib\]' /etc/pacman.conf; then
    echo "Enabling multilib in /etc/pacman.conf..."

    sudo sed -i \
      '/^[[:space:]]*#[[:space:]]*\[multilib\]/,/^[[:space:]]*#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/{
        s/^[[:space:]]*#[[:space:]]*\[multilib\]/[multilib]/
        s/^[[:space:]]*#[[:space:]]*Include = \/etc\/pacman\.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/
      }' \
      /etc/pacman.conf
  else
    echo "No [multilib] section found in /etc/pacman.conf. Skipping."
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

  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"

  (
    cd "$tmpdir/yay"
    makepkg -si
  )

  rm -rf "$tmpdir"
}

install_zsh_extras() {
  local zshrc="$USER_HOME/.zshrc"
  local zsh_custom_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"
  local ohmyzsh_installer

  if [[ ! -d "$USER_HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    ohmyzsh_installer="$(mktemp)"
    curl -fsSL -o "$ohmyzsh_installer" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$ohmyzsh_installer"
    rm -f "$ohmyzsh_installer"
  else
    echo "Oh My Zsh already installed."
  fi

  mkdir -p "$zsh_custom_dir/themes" "$zsh_custom_dir/plugins"

  if [[ ! -d "$zsh_custom_dir/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom_dir/themes/powerlevel10k"
  else
    echo "Powerlevel10k already installed."
  fi

  if [[ ! -d "$zsh_custom_dir/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom_dir/plugins/zsh-autosuggestions"
  else
    echo "zsh-autosuggestions already installed."
  fi

  if [[ ! -d "$zsh_custom_dir/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
  else
    echo "zsh-syntax-highlighting already installed."
  fi

  touch "$zshrc"

  if grep -q '^export ZSH=' "$zshrc"; then
    sed -i 's|^export ZSH=.*|export ZSH="$HOME/.oh-my-zsh"|' "$zshrc"
  else
    printf '\nexport ZSH="$HOME/.oh-my-zsh"\n' >> "$zshrc"
  fi

  if grep -q '^ZSH_THEME=' "$zshrc"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
  else
    printf 'ZSH_THEME="powerlevel10k/powerlevel10k"\n' >> "$zshrc"
  fi

  if grep -q '^plugins=' "$zshrc"; then
    sed -i 's|^plugins=.*|plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting)|' "$zshrc"
  else
    printf 'plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting)\n' >> "$zshrc"
  fi

  if ! grep -q 'oh-my-zsh.sh' "$zshrc"; then
    printf 'source "$ZSH/oh-my-zsh.sh"\n' >> "$zshrc"
  fi
}

install_nvm_and_node_tools() {
  local nvm_version="v0.40.0"
  local nvm_installer

  export NVM_DIR="$USER_HOME/.nvm"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    echo "Installing nvm..."
    mkdir -p "$NVM_DIR"
    nvm_installer="$(mktemp)"
    curl -fsSL -o "$nvm_installer" "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
    PROFILE="$USER_HOME/.zshrc" bash "$nvm_installer"
    rm -f "$nvm_installer"
  else
    echo "nvm already installed."
  fi

  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts
  npm install -g nodemon eslint typescript tldr firebase-tools http-server
}

# ---------- user folders / files ----------
copy_dir_contents "$SCRIPT_DIR/.fonts" "$USER_HOME/.fonts"
copy_dir_contents "$SCRIPT_DIR/.icons" "$USER_HOME/.icons"

for dir in ".fonts" ".icons" "Code"; do
  mkdir -p "$USER_HOME/$dir"
done

# ---------- config symlinks ----------
CONFIG_DIR="$USER_HOME/.config"

mkdir -p "$CONFIG_DIR"

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

if prompt_yes_no "Do you want to install PC or Laptop configs (y=PC | n=Laptop)"; then
  echo "Linking PC configs..."
  CONFIG_SRC_DIR="$SCRIPT_DIR/configs"
else
  echo "Linking laptop configs..."
  CONFIG_SRC_DIR="$SCRIPT_DIR/configs-laptop"
fi

if [[ ! -d "$CONFIG_SRC_DIR" ]]; then
  echo "❌ Config source directory not found: $CONFIG_SRC_DIR"
  exit 1
fi

for item in "${config_items[@]}"; do
  SRC="$CONFIG_SRC_DIR/$item"
  DST="$CONFIG_DIR/$item"

  if [[ ! -e "$SRC" ]]; then
    echo "⚠ Source not found: $SRC, skipping."
    continue
  fi

  echo "Replacing $DST with symlink to $SRC"

  # Remove existing file, dir, or symlink
  if [[ -e "$DST" || -L "$DST" ]]; then
    sudo rm -rf -- "$DST"
  fi

  # If it still exists, move it out of the way
  if [[ -e "$DST" || -L "$DST" ]]; then
    BACKUP="${DST}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "⚠ Could not delete $DST, moving it to $BACKUP"
    sudo mv -- "$DST" "$BACKUP"
  fi

  # Final safety check
  if [[ -e "$DST" || -L "$DST" ]]; then
    echo "❌ Failed to remove or move existing path: $DST"
    exit 1
  fi

  # -T prevents linking inside an existing directory
  ln -sT -- "$SRC" "$DST"

  echo "✔ Linked $item"
done

# ---------- main ----------
enable_multilib

pacman_remove_installed_only \
  snapshot \
  gnome-connections \
  gnome-maps \
  decibels \
  gnome-contacts \
  showtime \
  gnome-music \
  dolphin \
  gnome-weather \
  epiphany \
  gnome-software

# Full system upgrade
sudo pacman -Syu

# Repo packages
repo_pkgs=(
  ufw
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
)

amd_pkgs=(
  amdsmi
  rocm-smi-lib
)

intel_pkgs=(
  vulkan-intel
  intel-media-driver
  lib32-vulkan-intel
)

pacman_install_existing_only "${repo_pkgs[@]}"

while true; do
  echo "Select Graphics drivers to install:"
  echo "  1) AMD"
  echo "  2) Intel"
  echo "  3) Skip"
  read -rp "Enter choice [1-3]: " graphics_driver_choice

  case "$graphics_driver_choice" in
    1|[Aa]|[Aa][Mm][Dd])
      echo "Installing AMD Graphics drivers..."
      pacman_install_existing_only "${amd_pkgs[@]}"
      break
      ;;
    2|[Ii]|[Ii][Nn][Tt][Ee][Ll])
      echo "Installing Intel Graphics drivers..."
      pacman_install_existing_only "${intel_pkgs[@]}"
      break
      ;;
    3|[Ss]|[Ss][Kk][Ii][Pp])
      echo "Skipping Graphics driver installation."
      break
      ;;
    *)
      echo "Please enter 1, 2, or 3."
      ;;
  esac
done

# ---------- services ----------
sudo systemctl enable --now NetworkManager || true
sudo systemctl enable --now libvirtd
sudo systemctl enable --now docker
sudo systemctl start sshd
sudo systemctl enable sshd
sudo systemctl enable --now cronie.service

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
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
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
sudo pacman -S --needed flatpak
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
)

if prompt_yes_no "Do you want to install full or minimal flatpaks (y=full | n=minimal)"; then
  echo "Installing full Flatpaks..."
  flatpak install -y flathub "${apps[@]}" "${apps2[@]}"
else
  echo "Installing minimal Flatpaks..."
  flatpak install -y flathub "${apps[@]}"
fi

# ---------- shell / node ----------
install_zsh_extras
install_nvm_and_node_tools

if need_cmd zsh; then
  sudo chsh -s "$(command -v zsh)" "$ORIGINAL_USER"
else
  echo "zsh command not found. Skipping default shell change."
fi

echo "Done."
echo "Log out and back in, or reboot, so group changes take effect."
