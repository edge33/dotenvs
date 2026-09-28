# dotenvs

My Linux shell, font, terminal, and VS Code configuration.

## New Arch installation

Clone this repository and run the setup script as your regular user with sudo access:

```bash
git clone https://github.com/edge33/dotenvs.git
cd dotenvs
bash scripts/setup-arch.sh
```

If Git is not available yet, install it first with `sudo pacman -S git`. The script installs or updates Git, build tools, curl, Zsh, fontconfig, the Arch font packages, nvm, the latest Node.js LTS, yay, Apple fonts, and Visual Studio Code. It makes the latest LTS line the default for new shells, installs Zim and its modules including Powerlevel10k, installs the Material Icon Theme extension, and sets Zsh as the login shell.

The Arch fonts are `ttf-jetbrains-mono`, `ttf-dejavu`, `ttf-liberation`, `noto-fonts`, and `noto-fonts-emoji` from the official repositories, plus `apple-fonts` from the AUR. The script also downloads all four [MesloLGS NF font files](https://github.com/romkatv/powerlevel10k-media) used by Powerlevel10k and the VS Code terminal. Configure any other terminal app to use `MesloLGS NF`.

The script copies `.zshrc`, `.zimrc`, `.p10k.zsh`, `.config/fontconfig/fonts.conf`, and `vscode/settings.json` to your home configuration. It backs up differing existing files under `~/.local/share/dotenvs-backups/` before replacing them. You can rerun the script after pulling updates.

The script installs `visual-studio-code-bin` and `apple-fonts` from the AUR. Review their PKGBUILDs before running it if you want to inspect third party packages.

## Other Linux distributions

Install Zsh, Git, curl, Node.js via [nvm](https://github.com/nvm-sh/nvm), Zim, and Powerlevel10k for your distribution. Copy `.zshrc`, `.zimrc`, and `.p10k.zsh` to your home directory, `.config/fontconfig/fonts.conf` to `~/.config/fontconfig/fonts.conf`, and `vscode/settings.json` to `~/.config/Code/User/settings.json`.

Install JetBrains Mono, DejaVu, Liberation, Noto Sans, Noto Serif, Noto Color Emoji, and MesloLGS NF fonts. The four MesloLGS NF files are linked in the [Powerlevel10k font instructions](https://github.com/romkatv/powerlevel10k#manual-font-installation). Refresh fontconfig with `fc-cache -f` and set your terminal font to `MesloLGS NF`.

## GNOME shortcuts

If VS Code's Ctrl+Shift+Alt+Up/Down shortcuts clash with GNOME shortcuts, check the relevant GNOME settings. See [GNOME issue 1528](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/1528).
