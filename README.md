CachyOS + niri + noctalia + home-manager rice

> TODO: ansible script

### 1. Nix
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### 2. Home Manager
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
nix run home-manager/master -- init --switch
```

### 3. Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 4. Paru Packages
```bash
paru -S google-chrome obsidian anki blueman ghostty quickshell noctalia-shell hyprlock hypridle jetbrains-toolbox docker docker-compose
```

### 5. Docker Setup
```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```
Then log out/in for group to take effect.

### 6. Make Zsh Default
```bash
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/zsh
```

### 7. Clone Dotfiles and Stow
```bash
git clone git@github.com:fdegmecic/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow cachyOS
```
This symlinks all configs from `cachyOS/.config/` to `~/.config/`:
- `niri/` - compositor config
- `noctalia/` - shell/bar config
- `hypr/` - hyprlock/hypridle config
- `kanshi/` - monitor auto-switching
- `.face` - profile picture

### 8. Home Manager Config
```bash
# Remove the default home-manager config created in step 2
rm -rf ~/.config/home-manager

# Link our dotfiles home-manager instead
ln -sf ~/.dotfiles/home-manager ~/.config/home-manager

# Update flake and build
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .#fdegmecic-home-manager
```
This installs via nix:
- neovim (with nixCats plugins)
- zsh + zoxide + syntax highlighting
- CLI tools: yazi, eza, btop, fnm, bun, etc.
- fonts: Iosevka, JetBrains Mono Nerd Fonts
