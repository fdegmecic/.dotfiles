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

### 4. Clone Dotfiles and Stow
```bash
git clone git@github.com:fdegmecic/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow cachyOS
```

### 5. Home Manager Config
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

### 6. Make Zsh Default
```bash
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/zsh
```

### 7. Paru Packages
```bash
paru -S google-chrome obsidian anki ghostty quickshell noctalia-shell hyprlock hypridle jetbrains-toolbox docker docker-compose obs-studio papirus-icon-theme
```

### 8. Hyprlock Wallpaper
```bash
mkdir -p ~/.cache/hyprlock
```
Noctalia hook will symlink the wallpaper here for hyprlock's blur background.

### 9. Docker Setup
```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```
