#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo 'Run this script as your regular user, not root.' >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]] || ! grep -qx 'ID=arch' /etc/os-release; then
  echo 'This setup script requires Arch Linux.' >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo 'Git is required to clone this repository. Install Git before running this script.' >&2
  exit 1
fi

script_path=$(cd -- "$(dirname -- "$0")" && pwd)/$(basename -- "$0")
repo_dir=$(cd -- "$(dirname -- "$script_path")/.." && pwd)
font_dir="$HOME/.local/share/fonts"
backup_dir="$HOME/.local/share/dotenvs-backups/$(date +%Y%m%d-%H%M%S)"

# Start in Bash on a fresh install, then run the rest of this file in Zsh.
if [[ -z ${ZSH_VERSION:-} ]]; then
  echo 'Installing Zsh and switching the setup to it...'
  sudo pacman -Syu --needed --noconfirm curl zsh
  exec zsh -f "$script_path"
fi

install_config() {
  local source=$1 target=$2
  if [[ -f $target ]] && cmp -s "$source" "$target"; then
    return
  fi
  if [[ -e $target ]]; then
    mkdir -p "$backup_dir"
    cp -p -- "$target" "$backup_dir/$(basename "$target")"
  fi
  install -Dm644 -- "$source" "$target"
}

echo 'Installing Zim and shell configuration...'
install_config "$repo_dir/.zshrc" "$HOME/.zshrc"
install_config "$repo_dir/.zimrc" "$HOME/.zimrc"
install_config "$repo_dir/.p10k.zsh" "$HOME/.p10k.zsh"
zsh -ic 'zimfw install'
current_user=$(id -un)
if [[ $(getent passwd "$current_user" | cut -d: -f7) != "$(command -v zsh)" ]]; then
  sudo usermod -s "$(command -v zsh)" "$current_user"
fi

echo 'Installing nvm and Node.js LTS...'
export NVM_DIR="$HOME/.nvm"
if [[ ! -s $NVM_DIR/nvm.sh ]]; then
  if [[ -e $NVM_DIR ]]; then
    echo "Existing $NVM_DIR does not contain nvm.sh; resolve it before retrying." >&2
    exit 1
  fi
  git clone --depth 1 --branch v0.40.8 https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi
source "$NVM_DIR/nvm.sh"
nvm install --lts
if [[ ! -r $NVM_DIR/alias/default ]] || [[ $(<"$NVM_DIR/alias/default") != 'lts/*' ]]; then
  nvm alias default 'lts/*'
fi

echo 'Installing Arch packages and fonts...'
sudo pacman -S --needed --noconfirm \
  base-devel docker docker-compose fontconfig github-cli konsole openssh \
  ttf-jetbrains-mono ttf-dejavu ttf-liberation \
  noto-fonts noto-fonts-emoji

echo 'Enabling Docker for the current user...'
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi
if ! id -nG "$current_user" | tr ' ' '\n' | grep -qx docker; then
  sudo usermod -aG docker "$current_user"
fi
sudo systemctl disable docker.service
sudo systemctl enable --now docker.socket

if ! command -v paru >/dev/null 2>&1; then
  echo 'Installing paru...'
  paru_build_dir=$(mktemp -d)
  trap 'rm -rf -- "$paru_build_dir"' EXIT
  git clone https://aur.archlinux.org/paru.git "$paru_build_dir/paru"
  (cd "$paru_build_dir/paru" && makepkg -si --noconfirm)
  rm -rf -- "$paru_build_dir"
  trap - EXIT
fi

echo 'Installing AUR fonts and Visual Studio Code...'
paru -S --needed --noconfirm apple-fonts visual-studio-code-bin

mkdir -p "$font_dir"
for style in 'Regular' 'Bold' 'Italic' 'Bold Italic'; do
  file="MesloLGS NF $style.ttf"
  if [[ ! -s $font_dir/$file ]]; then
    url_file=${file// /%20}
    temp_font=$(mktemp "$font_dir/.meslo.XXXXXX")
    if ! curl --fail --location --retry 3 \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/$url_file" \
      --output "$temp_font"; then
      rm -f -- "$temp_font"
      exit 1
    fi
    mv -- "$temp_font" "$font_dir/$file"
  fi
done

install_config "$repo_dir/.config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
install_config "$repo_dir/.config/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"
install_config "$repo_dir/.local/share/konsole/SolarizedDark.profile" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/konsole/SolarizedDark.profile"
fc-cache

if ! command -v kwriteconfig6 >/dev/null 2>&1 ||
   ! command -v kreadconfig6 >/dev/null 2>&1; then
  echo 'Konsole requires kwriteconfig6 and kreadconfig6 to set its default profile.' >&2
  exit 1
fi
if [[ $(kreadconfig6 --file konsolerc --group 'Desktop Entry' --key DefaultProfile) != SolarizedDark.profile ]]; then
  kwriteconfig6 --file konsolerc --group 'Desktop Entry' --key DefaultProfile SolarizedDark.profile
fi

if command -v plasmashell >/dev/null 2>&1; then
  set_kde_font() {
    local group=$1 key=$2 family=$3 size=$4 current desired
    current=$(kreadconfig6 --file kdeglobals --group "$group" --key "$key")
    if [[ $current == *,* ]]; then
      desired="$family,${current#*,}"
    else
      desired="$family,$size,-1,5,50,0,0,0,0,0"
    fi
    if [[ $current != "$desired" ]]; then
      kwriteconfig6 --file kdeglobals --group "$group" --key "$key" "$desired"
    fi
  }

  echo 'Configuring KDE Plasma fonts...'
  set_kde_font General font 'SF Pro Text' 10
  set_kde_font General fixed 'JetBrains Mono' 10
  set_kde_font General smallestReadableFont 'SF Pro Text' 8
  set_kde_font General toolBarFont 'SF Pro Text' 10
  set_kde_font General menuFont 'SF Pro Text' 10
  set_kde_font WM activeFont 'SF Pro Display' 10
fi

code --install-extension pkief.material-icon-theme
code --install-extension biomejs.biome
bash "$repo_dir/scripts/setup-github-ssh.sh"

echo 'Arch development setup complete. Log out and back in to use Zsh and Docker without sudo.'
