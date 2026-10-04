# dotenvs

My Linux shell, font, terminal, and VS Code configuration.

## New Arch installation

Clone this repository and run the setup script as your regular user with sudo access:

```bash
git clone https://github.com/edge33/dotenvs.git
cd dotenvs
bash scripts/setup-arch.sh
```

Git is required to clone the repository; if it is not available yet, install it first with `sudo pacman -S git`. The script installs curl and Zsh, switches its own execution to Zsh, and sets up Zim. It then clones nvm v0.40.8 into `~/.nvm`, installs the latest Node.js LTS, and makes that LTS line the default for new shells. It also installs build tools, fontconfig, the Arch font packages, Docker, Docker Compose, paru, Apple fonts, Konsole, Visual Studio Code, GitHub CLI, OpenSSH, and the Material Icon Theme and Biome extensions. Zsh becomes the login shell.

The Arch fonts are `ttf-jetbrains-mono`, `ttf-dejavu`, `ttf-liberation`, `noto-fonts`, and `noto-fonts-emoji` from the official repositories, plus `apple-fonts` from the AUR. The script also downloads all four [MesloLGS NF font files](https://github.com/romkatv/powerlevel10k-media) used by Powerlevel10k and the VS Code terminal. Configure any other terminal app to use `MesloLGS NF`.

The script copies `.zshrc`, `.zimrc`, `.p10k.zsh`, `.config/fontconfig/fonts.conf`, `.config/Code/User/settings.json`, and `.local/share/konsole/SolarizedDark.profile` to your home configuration. The versioned `.zshrc` loads nvm from `~/.nvm`. The script backs up differing existing files under `~/.local/share/dotenvs-backups/` before replacing them and skips unchanged files on later runs. You can rerun it after pulling updates.

The script installs `visual-studio-code-bin` and `apple-fonts` from the AUR via paru. Review their PKGBUILDs before running it if you want to inspect third party packages.

## Docker

The script installs `docker` and `docker-compose`, disables automatic startup of `docker.service`, enables `docker.socket`, and adds the current user to the `docker` group. Docker starts when a client connects to its socket. If Docker is already running when you rerun the script, it stays running until stopped or rebooted. Log out of the desktop session and back in before running `docker` or `docker compose` without `sudo`. Membership in the `docker` group grants root-level access to the host through Docker.

## GitHub SSH authentication

The setup checks for `~/.ssh/id_ed25519`. If the key is missing, it generates an Ed25519 key and prompts for a passphrase. If the private key exists but its public file is missing, it recreates the public file. It never replaces an existing key pair.

The script then uses GitHub CLI to compare the public key with the authentication keys on the active GitHub account. It uploads the public key only when absent. A first run may prompt for `gh auth login` or a permission refresh. The private key stays on the machine and is never copied into this repository. You can rerun this step alone with `bash scripts/setup-github-ssh.sh`.

## KDE Plasma fonts

On Plasma 6, the script uses `kreadconfig6` and `kwriteconfig6` to set the [KDE font groups](https://github.com/KDE/plasma-workspace/blob/master/kcms/fonts/fontssettings.kcfg) in `~/.config/kdeglobals`. General, menu, toolbar, and small text use SF Pro Text; window titles use SF Pro Display; fixed-width text uses JetBrains Mono. Existing sizes and styles are retained. The fontconfig file handles serif and emoji preferences. Log out and back in to apply changes to the Plasma session. The script skips this step when Plasma is not installed.

## Konsole

The script installs a [Konsole profile](.local/share/konsole/SolarizedDark.profile) using Konsole's built-in `Solarized` dark color scheme and MesloLGS NF at 12 pt. It sets this profile as Konsole's default in `konsolerc`, leaving other settings and profiles in place. The profile is copied to `${XDG_DATA_HOME:-$HOME/.local/share}/konsole/`.

## Other Linux distributions

Install Zsh, Git, curl, Node.js via [nvm](https://github.com/nvm-sh/nvm), Zim, and Powerlevel10k for your distribution. Copy `.zshrc`, `.zimrc`, and `.p10k.zsh` to your home directory, `.config/fontconfig/fonts.conf` and `.config/Code/User/settings.json` to the same paths under your home directory.

Install JetBrains Mono, DejaVu, Liberation, Noto Sans, Noto Serif, Noto Color Emoji, and MesloLGS NF fonts. The four MesloLGS NF files are linked in the [Powerlevel10k font instructions](https://github.com/romkatv/powerlevel10k#manual-font-installation). Refresh fontconfig with `fc-cache -f` and set your terminal font to `MesloLGS NF`.

## GNOME shortcuts

If VS Code's Ctrl+Shift+Alt+Up/Down shortcuts clash with GNOME shortcuts, check the relevant GNOME settings. See [GNOME issue 1528](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/1528).
