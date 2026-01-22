# Dotfiles
CachyOS + niri + noctalia + home-manager rice

> TODO: ansible script for these steps

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
paru -S google-chrome obsidian anki blueman ghostty quickshell noctalia-shell hyprlock hypridle
```

### 4. Make Zsh Default
```bash
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/zsh
```

### 5. Clone Dotfiles and Stow
```bash
git clone git@github.com:fdegmecic/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow cachyOS
```

### 6. Home Manager Config
```bash
ln -sf ~/.dotfiles/home-manager ~/.config/home-manager
cd ~/.config/home-manager
nix flake update
home-manager switch --flake .
```
