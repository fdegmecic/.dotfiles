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

### 3. Paru Packages
```bash
paru -S google-chrome obsidian anki blueman ghostty quickshell noctalia-shell hyprlock hypridle jetbrains-toolbox docker docker-compose
```

### 4. Docker Setup
```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```
Then log out/in for group to take effect.

### 5. Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

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

### 8. Home Manager Config
```bash
ln -sf ~/.dotfiles/home-manager ~/.config/home-manager
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .
```
