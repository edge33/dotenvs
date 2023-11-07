# dotenvs
My personal dotenv files for ArchLinux

## fonts

Install the required fonts 
apple-fonts (AUR)
ttf-jetbrains-mono (Arch)

```bash
pacman -S ttf-jetbrains-mono ttf-dejavu ttf-liberation noto-fonts
yay -S apple-fonts
```

move `local.conf` to `/etc/fonts/local.conf`

```
fc-cache
```

install Meslo NG for powerlevel10k