return {
  'mrcjkb/rustaceanvim',
  config = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(_, bufnr)
          vim.lsp.inlay_hint.enable(bufnr)

          vim.keymap.set('n', '<leader>ih', function()
            local local_bufnr = vim.api.nvim_get_current_buf()
            vim.lsp.inlay_hint.enable(local_bufnr, not vim.lsp.inlay_hint.is_enabled(local_bufnr))
          end, { desc = '[I]nlay [H]ints' })
        end,
      },
    }
  end,
}
