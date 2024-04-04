return {
	  {
    '/nvim-lualine/lualine.nvim',
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'pywal-nvim',
        },
        sections = {
          lualine_x = { 'filetype' },
          lualine_y = {},
        },
      }
    end,
  },

}
