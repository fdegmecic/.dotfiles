-- [[ Basic Keymaps ]]
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex, { desc = 'Exit current file' })

-- git
vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

-- yank to clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])

-- Exit terminal mode
-- vim.keymap.set('t', '<leader>pv', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.keymap.set('n', '<leader>m', function()
  vim.cmd 'wincmd l'
  vim.cmd 'q'
end)

vim.keymap.set('n', '<leader>n', function()
  local file_path = vim.fn.expand '%:p'
  local file_name = vim.fn.fnamemodify(file_path, ':t:r')

  local original_window = vim.api.nvim_get_current_win()
  local original_width = vim.api.nvim_win_get_width(original_window)
  local new_width = math.floor(original_width * 0.4)

  vim.cmd('rightbelow ' .. new_width .. 'vnew')

  local cmd = 'cargo test --color=always ' .. file_name .. '::test -- --show-output'

  vim.fn.termopen(cmd)
  vim.api.nvim_set_current_win(original_window)
end)

-- vim: ts=2 sts=2 sw=2 et
