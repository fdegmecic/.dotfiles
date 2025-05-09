-- [[ Configure and install plugins ]]
--  You can press `?` in this menu for help. Use `:q` to close the window
--  To update plugins you can run
--    :Lazy update
--
require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  'mbbill/undotree',
  -- 'tpope/vim-surround',
  -- 'tpope/vim-fugitive',

  require 'kickstart/plugins/pywal',
  require 'kickstart/plugins/lualine',
  require 'kickstart/plugins/comment',
  require 'kickstart/plugins/gitsigns',
  -- require 'kickstart/plugins/which-key',
  require 'kickstart/plugins/telescope',
  require 'kickstart/plugins/conform',
  require 'kickstart/plugins/cmp',
  require 'kickstart/plugins/todo-comments',
  require 'kickstart/plugins/mini',
  require 'kickstart/plugins/treesitter',
  require 'kickstart/plugins/fugitive',
  require 'kickstart/plugins/harpoon',
  require 'kickstart/plugins/autopairs',
  require 'kickstart/plugins/oil',
  require 'kickstart/plugins/lspconfig',
  require 'kickstart/plugins/rustacean',
  require 'kickstart/plugins/dadbod',
  require 'kickstart/plugins/copilot',
  require 'kickstart/plugins/wilder',

  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  -- { import = 'custom.plugins' },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {},
  },
})

-- vim: ts=2 sts=2 sw=2 et
