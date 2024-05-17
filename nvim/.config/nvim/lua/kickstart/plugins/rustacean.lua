return {
  'mrcjkb/rustaceanvim',
  version = '^4',
  config = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(client, bufnr)
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(bufnr, true)
          end
          vim.keymap.set('n', '<leader>ih', function()
            local local_bufnr = vim.api.nvim_get_current_buf()
            vim.lsp.inlay_hint.enable(local_bufnr, not vim.lsp.inlay_hint.is_enabled(local_bufnr))
          end, { desc = '[I]nlay [H]ints' })
        end,
      },
      settings = {
        ['rust-analyzer'] = {
          checkOnSave = {
            command = 'clippy',
          },
          cargo = {
            allFeatures = true,
          },
          inlayHints = {
            enable = true,
            parameterHints = true,
            chainingHints = true,
            typeHints = true,
          },
          diagnostics = {
            enable = true,
          },
          procMacro = {
            enable = true,
          },
        },
      },
    }
  end,
}
