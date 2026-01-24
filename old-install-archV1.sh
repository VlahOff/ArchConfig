#!/bin/bash
# Enable multilib /etc/pacman.conf

sudo pacman -Syu -y

sudo pacman -S --needed virt-manager virt-viewer qemu-full libvirt dnsmasq iptables-nft edk2-ovmf swtpm docker base-devel git gnome-tweaks github-cli gparted ncdu btop htop curl timeshift sqlite tldr zsh hyprpaper hypridle hyprlock hyprpolkitagent hyprpicker mako waybar network-manager-applet lxappearance blueman xdg-desktop-portal-hyprland rofi solaar gnome-themes-extra powertop fastfetch amdsmi fontconfig ttf-firacode-nerd ttf-fira-code bleachbit woff2-font-awesome otf-font-awesome file-roller grim hplip util-linux flatpak goverlay mangohud steam gamescope

sudo systemctl enable --now libvirtd
sudo virsh net-autostart default
sudo virsh net-start default
sudo usermod -aG libvirt $(whoami)
sudo systemctl enable --now docker


git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -Sy brave-bin visual-studio-code-bin clipman wlogout

apps=(
  "com.github.tchx84.Flatseal"
  "org.gnome.Calendar"
  "org.gnome.Loupe"
  "org.pulseaudio.pavucontrol"
  "org.gtk.Gtk3theme.Adwaita-dark"
  "com.belmoussaoui.Authenticator"
  "com.discordapp.Discord"
  "com.github.PintaProject.Pinta"
  "com.google.Chrome"
  "com.microsoft.Edge"
  "com.mongodb.Compass"
  "com.spotify.Client"
  "com.transmissionbt.Transmission"
  "fr.handbrake.ghb"
  "io.github.shiftey.Desktop"
  "io.gitlab.adhami3310.Converter"
  "org.blender.Blender"
  "org.gimp.GIMP"
  "org.gnome.gThumb"
  "org.gnome.meld"
  "org.mozilla.firefox"
  "org.onlyoffice.desktopeditors"
  "org.videolan.VLC"
  "rest.insomnia.Insomnia"
  "flathub io.github.flattool.Warehouse"
  "flathub app.zen_browser.zen"
  "flathub com.anydesk.Anydesk"
  "net.davidotek.pupgui2"
)

flatpak install flathub "${apps[@]}" -y