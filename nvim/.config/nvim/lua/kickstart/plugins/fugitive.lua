return {
  {
    'tpope/vim-fugitive',
    config = function()
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = vim.api.nvim_create_augroup('fdegmecic_fugitive', {}),
        pattern = '*',
        callback = function()
          if vim.bo.ft ~= 'fugitive' then
            return
          end

          local bufnr = vim.api.nvim_get_current_buf()
          local opts = { buffer = bufnr, remap = false }
          vim.keymap.set('n', '<leader>p', function()
            vim.cmd.Git 'push'
          end, opts)

          vim.keymap.set('n', '<leader>P', function()
            vim.cmd.Git 'pull --rebase'
          end, opts)
          vim.keymap.set('n', '<leader>ge', function()
            vim.cmd.Git 'config user.name fdegmecic'
            vim.cmd.Git 'config user.email 42947589+fdegmecic@users.noreply.github.com'
          end, opts)

          -- NOTE: It allows me to easily set the branch i am pushing and any tracking
          -- needed if i did not set the branch up correctly
          vim.keymap.set('n', '<leader>t', ':Git push -u origin ', opts)
        end,
      })
    end,
  },
}
