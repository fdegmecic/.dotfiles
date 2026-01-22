return {
  {
    '/AlphaTechnolog/pywal.nvim',
    name = 'pywal',
    priority = 10000,
    -- event = 'VimEnter',
    init = function()
      vim.cmd.colorscheme 'pywal'
    end,
  },
}
