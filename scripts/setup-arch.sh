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

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
nvm_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
font_dir="$HOME/.local/share/fonts"
backup_dir="$HOME/.local/share/dotenvs-backups/$(date +%Y%m%d-%H%M%S)"

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

echo 'Installing Arch packages and fonts...'
sudo pacman -Syu --needed --noconfirm \
  git base-devel curl zsh fontconfig \
  ttf-jetbrains-mono ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji

echo 'Installing nvm and Node.js LTS...'
if [[ ! -s $nvm_dir/nvm.sh ]]; then
  if [[ -e $nvm_dir ]]; then
    echo "Existing $nvm_dir does not contain nvm.sh; resolve it before retrying." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$nvm_dir")"
  git clone --depth 1 --branch v0.40.7 https://github.com/nvm-sh/nvm.git "$nvm_dir"
fi
export NVM_DIR=$nvm_dir
# nvm is a shell function, so load it in this process before installing Node.
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

echo 'Installing yay...'
if ! command -v yay >/dev/null 2>&1; then
  yay_build_dir=$(mktemp -d)
  trap 'rm -rf -- "$yay_build_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$yay_build_dir/yay"
  (cd "$yay_build_dir/yay" && makepkg -si --noconfirm)
  rm -rf -- "$yay_build_dir"
  trap - EXIT
fi

echo 'Installing AUR fonts and Visual Studio Code...'
yay -S --needed --noconfirm apple-fonts visual-studio-code-bin

mkdir -p "$font_dir"
for style in 'Regular' 'Bold' 'Italic' 'Bold Italic'; do
  file="MesloLGS NF $style.ttf"
  if [[ ! -s $font_dir/$file ]]; then
    url_file=${file// /%20}
    curl --fail --location --retry 3 \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/$url_file" \
      --output "$font_dir/$file"
  fi
done

echo 'Installing shell, font, and editor configuration...'
install_config "$repo_dir/.zshrc" "$HOME/.zshrc"
install_config "$repo_dir/.zimrc" "$HOME/.zimrc"
install_config "$repo_dir/.p10k.zsh" "$HOME/.p10k.zsh"
install_config "$repo_dir/.config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
install_config "$repo_dir/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
fc-cache -f

# Starting Zsh runs the Zim bootstrap in .zshrc and installs its modules.
zsh -ic 'zimfw install'
code --install-extension pkief.material-icon-theme --force

current_user=$(id -un)
if [[ $(getent passwd "$current_user" | cut -d: -f7) != "$(command -v zsh)" ]]; then
  sudo usermod -s "$(command -v zsh)" "$current_user"
fi

echo 'Arch development setup complete. Open a new terminal to use Zsh and Node.js LTS.'
