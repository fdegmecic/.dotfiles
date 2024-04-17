return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('oil').setup {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
        is_hidden_file = function(name)
          return vim.startswith(name, '.')
        end,
      },
    }
  end,
}
