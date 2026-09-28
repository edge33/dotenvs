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

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
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

# nvm's installer adds its startup lines to .zshrc. Compare against that final
# form so rerunning the setup does not replace .zshrc or create another backup.
install_zshrc() {
  local source="$repo_dir/.zshrc" target="$HOME/.zshrc"
  if [[ -f $target ]] && cmp -s <(
    cat "$source"
    printf '\nexport NVM_DIR="%s"\n[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"  # This loads nvm\n[ -s "$NVM_DIR/bash_completion" ] && \\. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion\n' "$nvm_profile_dir"
  ) "$target"; then
    return
  fi
  install_config "$source" "$target"
}

if [[ -n ${NVM_DIR:-} ]]; then
  nvm_dir=$NVM_DIR
elif [[ -s $HOME/.config/nvm/nvm.sh ]]; then
  nvm_dir="$HOME/.config/nvm"
elif [[ -n ${XDG_CONFIG_HOME:-} ]]; then
  nvm_dir="$XDG_CONFIG_HOME/nvm"
else
  nvm_dir="$HOME/.nvm"
fi
if [[ $nvm_dir == "$HOME"/* ]]; then
  nvm_profile_dir="\$HOME/${nvm_dir#"$HOME"/}"
else
  nvm_profile_dir=$nvm_dir
fi

# Zsh and Zim go first so the shell is ready before development tools.
echo 'Installing Zsh and Zim...'
sudo pacman -Syu --needed --noconfirm curl zsh
install_zshrc
install_config "$repo_dir/.zimrc" "$HOME/.zimrc"
install_config "$repo_dir/.p10k.zsh" "$HOME/.p10k.zsh"
zsh -ic 'zimfw install'
current_user=$(id -un)
if [[ $(getent passwd "$current_user" | cut -d: -f7) != "$(command -v zsh)" ]]; then
  sudo usermod -s "$(command -v zsh)" "$current_user"
fi

echo 'Installing nvm and Node.js LTS...'
# Point nvm's installer at .zshrc even when the current login shell is Bash.
if [[ ! -s $nvm_dir/nvm.sh ]] ||
   ! grep -Fq '$NVM_DIR/nvm.sh' "$HOME/.zshrc" ||
   [[ $(NVM_DIR=$nvm_dir bash -c 'source "$NVM_DIR/nvm.sh"; nvm --version') != 0.40.8 ]]; then
  curl -o- --fail --silent --show-error https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh |
    PROFILE="$HOME/.zshrc" NVM_DIR="$nvm_dir" bash
fi
export NVM_DIR=$nvm_dir
source "$NVM_DIR/nvm.sh"
nvm install --lts
if [[ ! -r $NVM_DIR/alias/default ]] || [[ $(<"$NVM_DIR/alias/default") != 'lts/*' ]]; then
  nvm alias default 'lts/*'
fi

echo 'Installing Arch packages and fonts...'
sudo pacman -S --needed --noconfirm \
  base-devel fontconfig ttf-jetbrains-mono ttf-dejavu ttf-liberation \
  noto-fonts noto-fonts-emoji

if ! command -v yay >/dev/null 2>&1; then
  echo 'Installing yay...'
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
fc-cache
code --install-extension pkief.material-icon-theme
code --install-extension biomejs.biome

echo 'Arch development setup complete. Open a new terminal to use Zsh and Node.js LTS.'
