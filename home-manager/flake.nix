{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  outputs = { self, nixpkgs, home-manager, nixCats, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      inherit (nixCats) utils;
      luaPath = ./lua;

      dependencyOverlays = [
        (utils.standardPluginOverlay inputs)
      ];

      categoryDefinitions = { pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
        startupPlugins = {
          general = with pkgs.vimPlugins; [
            plenary-nvim
            nvim-web-devicons
            telescope-nvim
            telescope-fzf-native-nvim
            telescope-ui-select-nvim
            nvim-treesitter.withAllGrammars
            nvim-lspconfig
            fidget-nvim
            nvim-cmp
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            luasnip
            cmp_luasnip
            friendly-snippets
            lspkind-nvim
            copilot-lua
            copilot-cmp
            gitsigns-nvim
            vim-fugitive
            lualine-nvim
            todo-comments-nvim
            indent-blankline-nvim
            harpoon2
            oil-nvim
            nvim-autopairs
            mini-nvim
            vim-sleuth
            undotree
            comment-nvim
            tokyonight-nvim
            vim-dadbod
            vim-dadbod-ui
            vim-dadbod-completion
            rustaceanvim
          ];
        };

        lspsAndRuntimeDeps = {
          general = with pkgs; [
            lua-language-server
            pyright
            nodePackages.typescript-language-server
            tailwindcss-language-server
            vscode-langservers-extracted
            rust-analyzer
            stylua
            prettierd
            eslint_d
            ripgrep
            fd
            nodejs
          ];
        };
      };

      packageDefinitions = {
        nvim = { pkgs, name, ... }: {
          settings = {
            wrapRc = true;
            aliases = [ "vim" "vi" ];
          };
          categories = {
            general = true;
          };
        };
      };

      defaultPackageName = "nvim";

      nixCatsBuilder = utils.baseBuilder luaPath {
        inherit nixpkgs system dependencyOverlays;
      } categoryDefinitions packageDefinitions;

      defaultPackage = nixCatsBuilder defaultPackageName;

    in
    {
      packages.${system} = utils.mkAllWithDefault defaultPackage;

      homeConfigurations."fdegmecic-home-manager" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = {
          nixCatsPackage = defaultPackage;
        };
      };
    };
}
