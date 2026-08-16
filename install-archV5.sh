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
		echo "Removing listed packages and their unused dependencies..."
		sudo pacman -Rs --noconfirm "${remove[@]}"
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

install_oh_my_zsh() {
	local oh_my_zsh_dir="$USER_HOME/.oh-my-zsh"
	local zshrc="$USER_HOME/.zshrc"

	if [[ -d "$oh_my_zsh_dir/.git" ]]; then
		echo "Oh My Zsh is already installed."
	elif [[ -e "$oh_my_zsh_dir" ]]; then
		echo "❌ $oh_my_zsh_dir exists but is not an Oh My Zsh Git checkout."
		return 1
	else
		echo "Installing Oh My Zsh..."

		(
			local installer
			installer="$(mktemp)"
			trap 'rm -f -- "$installer"' EXIT

			curl -fsSL \
				https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
				-o "$installer"
			RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$oh_my_zsh_dir" \
				sh "$installer" --unattended --keep-zshrc
		)
	fi

	if [[ ! -f "$zshrc" ]]; then
		if [[ ! -f "$oh_my_zsh_dir/templates/zshrc.zsh-template" ]]; then
			echo "❌ Oh My Zsh did not create $zshrc and its template is missing."
			return 1
		fi

		cp -- "$oh_my_zsh_dir/templates/zshrc.zsh-template" "$zshrc"
	fi
}

install_git_repo_if_missing() {
	local repo_url="$1"
	local destination="$2"

	if [[ -d "$destination/.git" ]]; then
		echo "Already installed: $destination"
		return 0
	fi

	if [[ -e "$destination" || -L "$destination" ]]; then
		echo "❌ $destination exists but is not a Git checkout."
		return 1
	fi

	mkdir -p -- "$(dirname -- "$destination")"
	git clone --depth=1 "$repo_url" "$destination"
}

configure_zshrc() {
	local zshrc="$USER_HOME/.zshrc"
	local zshrc_target="$zshrc"

	if [[ -L "$zshrc" ]]; then
		zshrc_target="$(readlink -f -- "$zshrc")"
	fi

	if [[ ! -f "$zshrc_target" ]]; then
		echo "❌ Zsh configuration file not found: $zshrc_target"
		return 1
	fi

	(
		local tmp
		tmp="$(mktemp "${zshrc_target}.v5.XXXXXX")"
		trap 'rm -f -- "$tmp"' EXIT

		awk \
			-v 'theme_line=ZSH_THEME="powerlevel10k/powerlevel10k"' \
			-v 'plugins_line=plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)' \
			'
      BEGIN {
        in_plugins = 0
        theme_written = 0
        plugins_written = 0
      }

      {
        if (in_plugins) {
          if ($0 ~ /\)[[:space:]]*(#.*)?$/) {
            in_plugins = 0
          }
          next
        }

        if ($0 ~ /^[[:space:]]*ZSH_THEME[[:space:]]*=/) {
          if (!theme_written) {
            print theme_line
            theme_written = 1
          }
          next
        }

        if ($0 ~ /^[[:space:]]*plugins[[:space:]]*=\(/) {
          if (!plugins_written) {
            print plugins_line
            plugins_written = 1
          }
          if ($0 !~ /\)[[:space:]]*(#.*)?$/) {
            in_plugins = 1
          }
          next
        }

        if ($0 ~ /^[[:space:]]*source[[:space:]].*oh-my-zsh\.sh/) {
          if (!theme_written) {
            print theme_line
            theme_written = 1
          }
          if (!plugins_written) {
            print plugins_line
            plugins_written = 1
          }
        }

        print
      }

      END {
        if (!theme_written) {
          print theme_line
        }
        if (!plugins_written) {
          print plugins_line
        }
      }
    ' "$zshrc_target" >"$tmp"

		chmod --reference="$zshrc_target" "$tmp"
		mv -- "$tmp" "$zshrc_target"
	)

	echo "Configured Powerlevel10k and Zsh plugins in $zshrc."
}

set_zsh_as_default_shell() {
	local current_shell
	local zsh_path

	zsh_path="$(command -v zsh)"
	current_shell="$(getent passwd "$ORIGINAL_USER" | cut -d: -f7)"

	if [[ "$current_shell" == "$zsh_path" ]]; then
		echo "Zsh is already the default shell."
		return 0
	fi

	echo "Setting Zsh as the default shell for $ORIGINAL_USER..."
	sudo usermod --shell "$zsh_path" "$ORIGINAL_USER"
}

ensure_nvm_zshrc_lines() {
	local zshrc="$USER_HOME/.zshrc"
	local line
	local -a missing_lines=()
	local -a nvm_lines=(
		'export NVM_DIR="$HOME/.nvm"'
		'[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
		'[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
	)

	for line in "${nvm_lines[@]}"; do
		if ! grep -Fxq -- "$line" "$zshrc"; then
			missing_lines+=("$line")
		fi
	done

	if ((${#missing_lines[@]})); then
		printf '\n%s\n' "${missing_lines[@]}" >>"$zshrc"
	fi
}

install_nvm_node_and_global_tools() {
	local nvm_dir="$USER_HOME/.nvm"
	local nvm_version="v0.40.6"
	local zshrc="$USER_HOME/.zshrc"
	local -a npm_global_tools=(
		nodemon
		eslint
		typescript
		http-server
	)

	if [[ -s "$nvm_dir/nvm.sh" ]]; then
		echo "NVM is already installed."
	elif [[ -e "$nvm_dir" ]]; then
		echo "❌ $nvm_dir exists but does not contain nvm.sh."
		return 1
	else
		echo "Installing NVM $nvm_version..."

		(
			local installer
			installer="$(mktemp)"
			trap 'rm -f -- "$installer"' EXIT

			curl -fsSL \
				"https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" \
				-o "$installer"
			PROFILE="$zshrc" NVM_DIR="$nvm_dir" bash "$installer"
		)
	fi

	ensure_nvm_zshrc_lines

	export NVM_DIR="$nvm_dir"
	# shellcheck disable=SC1091
	. "$NVM_DIR/nvm.sh"

	echo "Installing the latest Node.js LTS release..."
	nvm install --lts
	nvm alias default 'lts/*'

	echo "Installing global npm tools: ${npm_global_tools[*]}"
	npm install --global "${npm_global_tools[@]}"
}

install_post_install_shell_tools() {
	local oh_my_zsh_dir="$USER_HOME/.oh-my-zsh"
	local zsh_custom_dir="${ZSH_CUSTOM:-$oh_my_zsh_dir/custom}"

	install_oh_my_zsh
	install_git_repo_if_missing \
		https://github.com/romkatv/powerlevel10k.git \
		"$zsh_custom_dir/themes/powerlevel10k"
	install_git_repo_if_missing \
		https://github.com/zsh-users/zsh-autosuggestions \
		"$zsh_custom_dir/plugins/zsh-autosuggestions"
	install_git_repo_if_missing \
		https://github.com/zsh-users/zsh-syntax-highlighting.git \
		"$zsh_custom_dir/plugins/zsh-syntax-highlighting"
	configure_zshrc
	set_zsh_as_default_shell
	install_nvm_node_and_global_tools
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
	docker-compose
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
	chatgpt-desktop
)

yay -Syu --needed "${aur_pkgs[@]}"

# ---------- Flatpak ----------
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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
	org.inkscape.Inkscape
)

if prompt_yes_no "Do you want to install full or minimal flatpaks (y=full | n=minimal)"; then
	echo "Installing full Flatpaks..."
	flatpak install --user -y flathub "${apps[@]}" "${apps2[@]}"
else
	echo "Installing minimal Flatpaks..."
	flatpak install --user -y flathub "${apps[@]}"
fi

# Install user files only after all package phases have succeeded.
install_user_files

# Configure the interactive shell and per-user Node.js developer tools last.
install_post_install_shell_tools

echo "Done."
echo "Log out and back in, or reboot, so group changes take effect."
