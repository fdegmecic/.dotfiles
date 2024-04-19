return {
  'mrcjkb/rustaceanvim',
  config = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(_, bufnr)
          vim.lsp.inlay_hint.enable(bufnr)
          vim.keymap.set('n', '<leader>ih', function()
            vim.lsp.inlay_hint.enable(bufnr, not vim.lsp.inlay_hint.is_enabled(bufnr))
          end, { desc = '[I]nlay [Hints] - rust' })
        end,
      },
    }
  end,
}
