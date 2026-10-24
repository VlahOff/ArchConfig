#!/usr/bin/env bash
set -Eeuo pipefail

report_error() {
	local exit_code="$1"
	local line_number="$2"
	local failed_command="$3"

	printf '❌ Error: command failed with exit code %s at line %s: %s\n' \
		"$exit_code" "$line_number" "$failed_command" >&2
	if [[ -n "${CURRENT_STAGE:-}" ]]; then
		printf 'Run the installer again to resume at stage: %s\n' "$CURRENT_STAGE" >&2
	fi
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

installer_usage() {
	cat <<'EOF'
Usage: ./install-archV6.sh [--restart | --from STAGE]

With no options, resume an interrupted run or start a new installation.
  --restart      Start again from the system upgrade stage.
  --from STAGE   Start at a chosen stage, including failures from older scripts.
  --help         Show this help without changing the system.

Stages: system packages services aur flatpak appimages configs shell
Example: ./install-archV6.sh --from flatpak
EOF
}

save_checkpoint() {
	(
		local tmp
		tmp="$(mktemp "$STATE_DIR/.next-stage.XXXXXX")"
		trap 'rm -f -- "$tmp"' EXIT
		printf '%s\n' "$1" >"$tmp"
		mv -- "$tmp" "$STATE_DIR/next-stage"
	)
}

install_flatpak_with_retry() {
	local app="$1"
	local attempt response exit_code

	if grep -Fxq -- "$app" "$STATE_DIR/flatpak-completed" "$STATE_DIR/flatpak-skipped" 2>/dev/null; then
		echo "Already handled in this run: $app"
		return 0
	fi

	while true; do
		for attempt in 1 2 3; do
			echo "Installing $app (attempt $attempt/3)..."
			if flatpak install --user --or-update -y flathub "$app"; then
				printf '%s\n' "$app" >>"$STATE_DIR/flatpak-completed"
				return 0
			else
				exit_code="$?"
				if [[ "$exit_code" -eq 130 || "$exit_code" -eq 143 ]]; then
					echo "Installation interrupted. Run the installer again to resume Flatpaks." >&2
					exit "$exit_code"
				fi
			fi
			if ((attempt < 3)); then
				echo "Download or installation failed; retrying in 5 seconds..." >&2
				sleep 5
			fi
		done

		while true; do
			if ! read -rp "Could not install $app. Retry, skip this app, or stop (r/s/q): " response; then
				echo "❌ Input closed. Run the installer again to resume Flatpaks." >&2
				exit 1
			fi
			case "$response" in
			[Rr]) break ;;
			[Ss])
				printf '%s\n' "$app" >>"$STATE_DIR/flatpak-skipped"
				echo "⚠ Skipping $app; it has not been installed successfully."
				return 0
				;;
			[Qq])
				echo "Stopped. Run the installer again to resume Flatpaks."
				exit 1
				;;
			*) echo "Please answer r, s, or q." ;;
			esac
		done
	done
}

prompt_yes_no() {
	local prompt_message="$1"
	local response

	while true; do
		if ! read -rp "$prompt_message (y/n): " response; then
			echo "❌ Input closed while waiting for an answer. Installation cancelled." >&2
			exit 1
		fi

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
	if pacman-conf --repo multilib Server 2>/dev/null | grep . >/dev/null; then
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

	if ! pacman-conf --repo multilib Server 2>/dev/null | grep . >/dev/null; then
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
		local tmp backup quoted_zsh_dir
		tmp="$(mktemp "${zshrc_target}.v6.XXXXXX")"
		trap 'rm -f -- "$tmp"' EXIT

		printf -v quoted_zsh_dir '%q' "$USER_HOME/.oh-my-zsh"
		# Preserve user code, including multiline arrays and commands after semicolons.
		# Pass the shell-quoted path through the environment so awk does not unescape it.
		ARCHCONFIG_ZSH_LINE="export ZSH=$quoted_zsh_dir" awk '
      function write_settings(include_source) {
        print "# >>> ArchConfig V6 shell settings >>>"
        print ENVIRON["ARCHCONFIG_ZSH_LINE"]
        print "ZSH_THEME=\"powerlevel10k/powerlevel10k\""
        print "plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)"
        if (include_source) {
          print "source \"$ZSH/oh-my-zsh.sh\""
        }
        print "# <<< ArchConfig V6 shell settings <<<"
        settings_written = 1
      }

      BEGIN {
        in_settings = 0
        settings_written = 0
      }

      {
        if ($0 == "# >>> ArchConfig V6 shell settings >>>") {
          in_settings = 1
          next
        }
        if ($0 == "# <<< ArchConfig V6 shell settings <<<") {
          in_settings = 0
          next
        }
        if (in_settings) {
          next
        }

        if (!settings_written && $0 ~ /^[[:space:]]*(source|\.)[[:space:]].*oh-my-zsh\.sh/) {
          write_settings(0)
        }

        print
      }

      END {
        if (in_settings) {
          print "Unclosed ArchConfig settings block; leaving .zshrc unchanged." > "/dev/stderr"
          exit 1
        }
        if (!settings_written) {
          write_settings(1)
        }
      }
    ' "$zshrc_target" >"$tmp"

		zsh -n "$tmp"
		if cmp -s -- "$zshrc_target" "$tmp"; then
			return 0
		fi

		backup="$(mktemp "${zshrc_target}.pre-archconfig-v6.XXXXXX")"
		cp -p -- "$zshrc_target" "$backup"
		chmod --reference="$zshrc_target" "$tmp"
		mv -- "$tmp" "$zshrc_target"
		echo "Backed up the previous Zsh configuration to $backup."
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
			mkdir -p -- "$nvm_dir"
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
		llama.cpp
		mako
		nvim
		opencode
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

install_github_appimage() {
	local name="$1"
	local repo="$2"
	local pattern="$3"
	local icon_url="$4"
	local categories="$5"

	local app_dir="$HOME/Applications"
	local icon_dir="$HOME/.local/share/icons"
	local desktop_dir="$HOME/.local/share/applications"

	local target="$app_dir/$name.AppImage"
	local icon="$icon_dir/$name.png"
	local desktop="$desktop_dir/$name.desktop"

	local release asset url digest tmp

	mkdir -p "$app_dir" "$icon_dir" "$desktop_dir"

	echo "Checking $name releases..."

	release="$(curl -fsSL --retry 3 \
		"https://api.github.com/repos/$repo/releases/latest")"

	asset="$(jq -er --arg re "$pattern" '
        [.assets[] | select(.name | test($re))][0]
        | select(. != null)
        | [.browser_download_url, .digest]
        | @tsv
    ' <<<"$release")"

	IFS=$'\t' read -r url digest <<<"$asset"

	# Verify GitHub's published SHA256 digest
	if [[ ! "$digest" =~ ^sha256:[a-fA-F0-9]{64}$ ]]; then
		echo "Missing or invalid SHA256 for $name" >&2
		return 1
	fi

	digest="${digest#sha256:}"

	if [[ -f "$target" ]] &&
		printf '%s  %s\n' "$digest" "$target" |
		sha256sum --check --status; then
		echo "$name is already up to date."
	else
		tmp="$(mktemp "$app_dir/.$name.XXXXXX")"

		if ! curl -fL --retry 3 "$url" -o "$tmp"; then
			rm -f "$tmp"
			return 1
		fi

		if ! printf '%s  %s\n' "$digest" "$tmp" |
			sha256sum --check --status; then
			echo "Checksum verification failed: $name" >&2
			rm -f "$tmp"
			return 1
		fi

		chmod +x "$tmp"
		mv -f "$tmp" "$target"
		echo "$name installed successfully."
	fi

	# Download the official application icon
	if [[ ! -s "$icon" ]]; then
		if ! curl -fL --retry 3 "$icon_url" -o "$icon"; then
			rm -f "$icon"
			echo "Could not download icon for $name."
		fi
	fi

	local icon_entry="$icon"
	if [[ ! -s "$icon" ]]; then
		icon_entry="application-x-executable"
	fi

	cat >"$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec="$target" %U
Icon=$icon_entry
Terminal=false
Categories=$categories
EOF
}

install_appimages() {
	install_github_appimage \
		"Helium" \
		"imputnet/helium-linux" \
		'^helium-.*-x86_64\.AppImage$' \
		"https://raw.githubusercontent.com/imputnet/helium/main/resources/branding/product_logo_200.png" \
		"Network;WebBrowser;"

	install_github_appimage \
		"Joplin" \
		"laurent22/joplin" \
		'^Joplin-[0-9].*\.AppImage$' \
		"https://joplinapp.org/images/Icon512.png" \
		"Office;Utility;"
}

stage_system() {
	enable_multilib

	# Refresh package databases and complete the full upgrade as one operation.
	sudo pacman -Syu
}

stage_packages() {
	local -a remove_pkgs=(
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
	local -a repo_pkgs=(
		base-devel
		bind
		bleachbit
		blueman
		bluez
		bluez-utils
		brightnessctl
		btop
		cantarell-fonts
		chromium
		clamav
		cmake
		cronie
		cups
		curl
		dmidecode
		dnsmasq
		docker
		docker-compose
		edk2-ovmf
		fastfetch
		file-roller
		flatpak
		fuse2
		fontconfig
		gamemode
		gamescope
		ggml-vulkan
		git
		github-cli
		gnome-themes-extra
		gnome-tweaks
		goverlay
		gparted
		grim
		hplip
		htop
		hypridle
		hyprland
		hyprlock
		hyprpaper
		hyprpicker
		hyprpolkitagent
		inxi
		iptables
		jq
		kitty
		libvirt
		llama-cpp
		lxappearance
		mako
		man-db
		man-pages
		mangohud
		mesa-demos
		ncdu
		nemo
		neovim
		network-manager-applet
		networkmanager
		noto-fonts-cjk
		nvme-cli
		openssh
		otf-font-awesome
		powertop
		python-pip
		qemu-full
		reflector
		ripgrep
		rofi
		samba
		shfmt
		slurp
		solaar
		spirv-headers
		sqlite
		steam
		swtpm
		tesseract
		tesseract-data-bul
		timeshift
		tldr
		tmux
		ttf-fira-code
		ttf-firacode-nerd
		ttf-jetbrains-mono
		ttf-jetbrains-mono-nerd
		ttf-liberation
		ufw
		unrar
		util-linux
		v4l-utils
		vi
		virt-manager
		virt-viewer
		vulkan-radeon
		vulkan-tools
		waybar
		wine
		wl-clipboard
		wlr-randr
		woff2-font-awesome
		xdg-desktop-portal-hyprland
		xorg-xhost
		zsh
	)

	local -a amd_monitoring_pkgs=(
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
}

stage_services() {
	# ---------- services ----------
	sudo systemctl enable --now NetworkManager || true
	sudo systemctl enable --now bluetooth.service
	sudo systemctl enable --now libvirtd
	sudo systemctl enable --now docker
	sudo systemctl enable --now cronie.service
	sudo systemctl enable --now cups.socket
	sudo systemctl enable --now reflector.timer

	local ssh_enabled=0
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
	# LocalSend uses this port for discovery and file transfers over TCP and UDP.
	sudo ufw allow 53317
	sudo ufw enable
	sudo systemctl enable --now ufw.service
}

stage_aur() {
	# ---------- AUR packages ----------
	install_yay_if_missing

	local -a aur_pkgs=(
		brave-bin
		visual-studio-code-bin
		clipman
		wlogout
		chatgpt-desktop
	)

	yay -Syu --needed "${aur_pkgs[@]}"
}

stage_flatpak() {
	# ---------- Flatpak ----------
	flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	local -a apps=(
		io.github.ebonjaeger.bluejay
		org.gnome.Calendar
		org.mozilla.firefox
		com.github.tchx84.Flatseal
		it.mijorus.gearlever
		org.gnome.Loupe
		org.gnome.meld
		org.videolan.VLC
		org.pulseaudio.pavucontrol
		io.github.flattool.Warehouse
		org.flathub.flatpak-external-data-checker
		org.gtk.Gtk3theme.Adwaita-dark
		org.localsend.localsend_app
	)

	local -a apps2=(
		com.anydesk.Anydesk
		org.blender.Blender
		com.usebruno.Bruno
		com.discordapp.Discord
		io.github.shiftey.Desktop
		org.gimp.GIMP
		com.google.Chrome
		fr.handbrake.ghb
		org.inkscape.Inkscape
		com.microsoft.Edge
		io.missioncenter.MissionCenter
		com.mongodb.Compass
		org.onlyoffice.desktopeditors
		com.github.PintaProject.Pinta
		net.davidotek.pupgui2
		com.rustdesk.RustDesk
		com.spotify.Client
		com.transmissionbt.Transmission
		com.viber.Viber
		com.vscodium.codium
		eu.codepoems.xl-converter
		one.ablaze.floorp
		app.zen_browser.zen
	)

	local profile app
	if [[ -f "$STATE_DIR/flatpak-profile" ]]; then
		profile="$(cat -- "$STATE_DIR/flatpak-profile")"
	else
		if prompt_yes_no "Do you want to install full or minimal flatpaks (y=full | n=minimal)"; then
			profile=full
		else
			profile=minimal
		fi
		printf '%s\n' "$profile" >"$STATE_DIR/flatpak-profile"
	fi

	case "$profile" in
	full) apps+=("${apps2[@]}") ;;
	minimal) ;;
	*)
		echo "❌ Invalid saved Flatpak profile. Use --from flatpak to choose again." >&2
		return 1
		;;
	esac

	echo "Installing $profile Flatpaks..."
	for app in "${apps[@]}"; do
		install_flatpak_with_retry "$app"
	done
}

stage_appimages() {
	# ---------- AppImages ----------
	if prompt_yes_no "Install Helium and Joplin AppImages"; then
		install_appimages
	fi
}

stage_configs() {
	# Link user files after the package stages and any explicit Flatpak skips.
	install_user_files
}

stage_shell() {
	# Configure the interactive shell and per-user Node.js developer tools last.
	install_post_install_shell_tools
}

# ---------- main ----------
INSTALL_STAGES=(system packages services aur flatpak appimages configs shell)
requested_stage=""
CURRENT_STAGE=""
while (($#)); do
	case "$1" in
	--help | -h)
		installer_usage
		exit 0
		;;
	--restart)
		if [[ -n "$requested_stage" ]]; then
			echo "❌ Choose only one of --restart or --from." >&2
			exit 2
		fi
		requested_stage=system
		shift
		;;
	--from)
		if [[ -n "$requested_stage" || $# -lt 2 || -z "$2" ]]; then
			echo "❌ --from requires one stage and cannot be combined with --restart." >&2
			exit 2
		fi
		requested_stage="$2"
		shift 2
		;;
	*)
		echo "❌ Unknown option: $1" >&2
		installer_usage >&2
		exit 2
		;;
	esac
done

# Keep checkpoints separate for each user and checkout. Checkpoint files contain
# stage names and app IDs only; never source them as shell code.
state_key="$(printf '%s' "$SCRIPT_DIR" | sha256sum)"
STATE_DIR="${XDG_STATE_HOME:-$USER_HOME/.local/state}/archconfig/install-arch-v6/${state_key%% *}"

# Validate an explicit stage before creating or changing progress files.
if [[ -n "$requested_stage" ]]; then
	stage_found=0
	for stage in "${INSTALL_STAGES[@]}"; do
		if [[ "$stage" == "$requested_stage" ]]; then
			stage_found=1
			break
		fi
	done
	if ((stage_found == 0)); then
		echo "❌ Unknown stage: $requested_stage" >&2
		installer_usage >&2
		exit 2
	fi
fi

mkdir -p -- "$STATE_DIR"
exec {progress_lock_fd}>"$STATE_DIR/lock"
if ! flock -n "$progress_lock_fd"; then
	echo "❌ Another installer is already running for this checkout." >&2
	exit 1
fi

start_stage="$requested_stage"
if [[ -z "$start_stage" && -f "$STATE_DIR/next-stage" ]]; then
	start_stage="$(cat -- "$STATE_DIR/next-stage")"
fi
if [[ -z "$start_stage" || "$start_stage" == complete || -n "$requested_stage" ]]; then
	start_stage="${requested_stage:-system}"
	rm -f -- "$STATE_DIR/flatpak-profile" "$STATE_DIR/flatpak-completed" "$STATE_DIR/flatpak-skipped"
else
	echo "Resuming interrupted installation at stage: $start_stage"
fi

start_index=-1
for i in "${!INSTALL_STAGES[@]}"; do
	if [[ "${INSTALL_STAGES[i]}" == "$start_stage" ]]; then
		start_index="$i"
		break
	fi
done
if ((start_index < 0)); then
	echo "❌ Invalid saved stage. Use --restart or --from STAGE to recover." >&2
	exit 1
fi

save_checkpoint "$start_stage"
for ((i = start_index; i < ${#INSTALL_STAGES[@]}; i++)); do
	CURRENT_STAGE="${INSTALL_STAGES[i]}"
	echo "--- Stage: $CURRENT_STAGE ---"
	# Keep stage calls outside conditionals so errexit still stops on failures.
	"stage_$CURRENT_STAGE"
	save_checkpoint "${INSTALL_STAGES[i + 1]:-complete}"
done
CURRENT_STAGE=""

if [[ -s "$STATE_DIR/flatpak-skipped" ]]; then
	echo "⚠ These Flatpaks were skipped and have not been installed successfully:"
	cat -- "$STATE_DIR/flatpak-skipped"
	echo "To retry them, run this installer with --from flatpak."
fi
echo "Done."
echo "Log out and back in, or reboot, so group changes take effect."
