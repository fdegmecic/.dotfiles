return {
  'mrcjkb/rustaceanvim',
  version = '^4',
  config = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function()
          vim.lsp.inlay_hint.enable(true)
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
