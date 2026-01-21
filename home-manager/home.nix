{ config, pkgs, nixCatsPackage, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "fdegmecic";
  home.homeDirectory = "/home/fdegmecic";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.yazi
    pkgs.eza
    pkgs.webcord
    pkgs.btop
    nixCatsPackage
    # pkgs.obsidian
    # pkgs.ghostty
    # pkgs.noctalia-shell
    # pkgs.niri
  ];

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -la";
      update = "sudo pacman -Syu";
      rebuild = "home-manager switch --flake ~/.dotfiles/home-manager#fdegmecic-home-manager";
      nix-update = "nix flake update --flake ~/.dotfiles/home-manager && home-manager switch --flake ~/.dotfiles/home-manager#fdegmecic-home-manager";
    };

    initContent = ''
      export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$HOME/.local/bin:$PATH"
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
  };

  # Neovim via nixCats (defined in ./nvim/)
  # programs.neovim not used - nixCats handles everything

  # Ghostty installed via paru -S ghostty (nix version has OpenGL issues)
  # programs.ghostty = {
  #   enable = true;
  #   settings = {
  #     gtk-single-instance = true;
  #   };
  # };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/fdegmecic/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Enables XDG integration so Nix apps appear in app launchers (wofi, etc.)
  targets.genericLinux.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
