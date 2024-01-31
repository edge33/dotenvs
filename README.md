# dotenvs

My personal dotenv files for Linux

## fonts

### ARCH

Install the required fonts
apple-fonts (AUR)
ttf-jetbrains-mono (Arch)

```bash
pacman -S ttf-jetbrains-mono ttf-dejavu ttf-liberation noto-fonts
yay -S apple-fonts
```

### FEDORA

```
mkdir ~/.local/share/fonts && cd ~/.local/share/fonts
wget https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/raw/master/SF-Pro-Display-Regular.otf

wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf


sudo dnf install dejavu-fonts-all
sudo dnf install liberation-fonts

```

move `fonts/fonts.conf` to `~/.config/fontconfig/fonts.conf`

```
fc-cache
```

## ZSH

move `.p10k.` zsh to `~/`,

install Meslo fonts as per fonts section of this readme,

configure the terminal app to use `MesloLGS NF` font

install Meslo NG for powerlevel10k

## Gnome settings

in order to allow shortcuts in vscode like ctrl + shit + alt + up/down

check if there are clashes with gnome shortcuts
https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/1528
