# dotenvs
My personal dotenv files for ArchLinux

## fonts

Install the required fonts 
apple-fonts (AUR)
ttf-jetbrains-mono (Arch)

pacman -S ttf-jetbrains-mono
yay -S apple-fonts
sudo pacman -S ttf-dejavu ttf-liberation noto-fonts

move local.conf to /etc/fonts/local.conf
then
fc-cache


install Meslo NG for powerlevel10k