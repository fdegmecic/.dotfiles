-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- ============================================================================
-- OPTIONS
-- ============================================================================
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.showmode = false
opt.clipboard = 'unnamedplus'
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = 'yes'
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = false
opt.inccommand = 'split'
opt.cursorline = true
opt.hlsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.fillchars = { eob = ' ' }
opt.winborder = 'rounded'

-- ============================================================================
-- KEYMAPS
-- ============================================================================
local keymap = vim.keymap.set

-- Clear search highlight
keymap('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostics
keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic' })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic' })
keymap('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic error messages' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Plugins
keymap('n', '<leader>gs', vim.cmd.Git, { desc = 'Git status' })
keymap('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = 'Toggle undotree' })

-- Yank to clipboard
keymap({ 'n', 'v' }, '<leader>y', [["+y]])
keymap('n', '<leader>Y', [["+Y]])

-- Make file executable
keymap('n', '<leader>X', '<cmd>!chmod +x %<CR>', { silent = true })

-- Tmux sessionizer
keymap('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')

-- Move selected line up/down
keymap('v', 'J', ":m '>+1<CR>gv=gv")
keymap('v', 'K', ":m '<-2<CR>gv=gv")

-- Jumping centers cursor
keymap('n', '<C-d>', '<C-d>zz')
keymap('n', '<C-u>', '<C-u>zz')
keymap('n', 'n', 'nzzzv')
keymap('n', 'N', 'Nzzzv')

-- Jump to start/end of line
keymap('n', 'L', '$')
keymap('n', 'H', '^')

-- Keep current buffer when pasting
keymap('x', '<leader>p', [["_dP]])

-- Quick find/replace for word under cursor
keymap('n', 'S', function()
  local cmd = ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>'
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end)

-- Quickfix navigation
keymap('n', '<C-k>', '<cmd>cnext<CR>zz')
keymap('n', '<C-j>', '<cmd>cprev<CR>zz')
keymap('n', '<leader>k', '<cmd>lnext<CR>zz')
keymap('n', '<leader>j', '<cmd>lprev<CR>zz')

-- Disable arrow keys
keymap('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
keymap('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
keymap('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
keymap('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Split navigation
keymap('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
keymap('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
keymap('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
keymap('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
keymap('t', '<C-h>', [[<C-\><C-n><C-w>h]], { desc = 'Move focus left from terminal' })
keymap('t', '<C-l>', [[<C-\><C-n><C-w>l]], { desc = 'Move focus right from terminal' })
keymap('t', '<C-j>', [[<C-\><C-n><C-w>j]], { desc = 'Move focus down from terminal' })
keymap('t', '<C-k>', [[<C-\><C-n><C-w>k]], { desc = 'Move focus up from terminal' })

-- Tab navigation
keymap('n', '<A-,>', '<Cmd>-tabnext<CR>')
keymap('n', '<A-.>', '<Cmd>+tabnext<CR>')

-- DBUI toggle
keymap('n', '<leader>db', function()
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft == 'dbui' or ft == 'dbout' or ft == 'sql' then
      vim.cmd 'tabprevious'
      return
    end
  end
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      if ft == 'dbui' or ft == 'dbout' or ft == 'sql' then
        vim.api.nvim_set_current_tabpage(tab)
        return
      end
    end
  end
  vim.cmd 'tabnew'
  vim.cmd 'DBUI'
end)

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- ============================================================================
-- COLORSCHEME
-- ============================================================================
-- Use pywal colors if available, fallback to tokyonight
local ok, _ = pcall(vim.cmd, 'colorscheme pywal')
if not ok then
  vim.cmd [[colorscheme tokyonight-moon]]
end

local function apply_theme_tweaks()
  for _, group in ipairs({
    'Normal', 'NormalNC', 'CursorLine',
    'EndOfBuffer', 'SignColumn', 'LineNr', 'FoldColumn', 'MsgArea',
  }) do
    vim.api.nvim_set_hl(0, group, { bg = 'none' })
  end
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#ffffff' })
  vim.api.nvim_set_hl(0, 'FloatTitle', { fg = '#ffffff', bold = true })
end
apply_theme_tweaks()
vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', callback = apply_theme_tweaks })
vim.api.nvim_create_autocmd('VimEnter', { callback = apply_theme_tweaks })

-- ============================================================================
-- PLUGIN CONFIGS
-- ============================================================================

-- Telescope
require('telescope').setup {
  defaults = {
    layout_config = { prompt_position = 'top' },
    sorting_strategy = 'ascending',
  },
  pickers = {
    find_files = {
      hidden = true,
      file_ignore_patterns = { '^.git/' },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_file_sorter = true,
      override_generic_sorter = true,
      case_mode = 'smart_case',
    },
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
  },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local builtin = require 'telescope.builtin'
keymap('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
keymap('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
keymap('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
keymap('n', '<leader>gf', builtin.git_files, { desc = '[G]it [F]iles' })
keymap('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
keymap('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
keymap('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
keymap('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
keymap('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
keymap('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
keymap('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })
keymap('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = 'Fuzzily search in current buffer' })
keymap('n', '<leader>sn', function()
  builtin.find_files { cwd = vim.fn.expand '~/.dotfiles/home-manager/lua' }
end, { desc = '[S]earch [N]eovim files' })

-- Gitsigns
require('gitsigns').setup {
  signs = {
    add = { text = '▎' },
    change = { text = '▎' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '▎' },
  },
}

-- Lualine
require('lualine').setup {
  options = {
    theme = 'auto',
    icons_enabled = true,
  },
}

-- Todo Comments
require('todo-comments').setup {}

-- Indent Blankline
vim.api.nvim_set_hl(0, 'IblScope', { link = 'Function' })
vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#3a3a3a', nocombine = true })
require('ibl').setup {
  indent = { char = '▏', highlight = 'IblIndent' },
  scope = { enabled = true, show_start = false, show_end = false },
}

-- Mini
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()

-- Autopairs
require('nvim-autopairs').setup {}

-- Comment
require('Comment').setup()

-- Oil
require('oil').setup {
  view_options = {
    show_hidden = true,
  },
}
keymap('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- Cloak (streamer mode for .env files)
require('cloak').setup {
  enabled = true,
  cloak_character = '*',
  highlight_group = 'Comment',
  patterns = {
    {
      file_pattern = { '.env*', '*.env', 'credentials*', '*secret*' },
      cloak_pattern = '=.+',
    },
  },
}
keymap('n', '<leader>ct', '<cmd>CloakToggle<CR>', { desc = '[C]loak [T]oggle' })

-- Harpoon
local harpoon = require 'harpoon'
harpoon:setup()
keymap('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon add file' })
keymap('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
keymap('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
keymap('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
keymap('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
keymap('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })

-- Claude Code
require('claudecode').setup()
keymap('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = '[C]laude [C]ode toggle' })
keymap('n', '<leader>cf', '<cmd>ClaudeCodeFocus<CR>', { desc = '[C]laude [F]ocus' })
keymap('n', '<leader>cb', '<cmd>ClaudeCodeAdd %<CR>', { desc = '[C]laude add [B]uffer' })
keymap('v', '<leader>cs', '<cmd>ClaudeCodeSend<CR>', { desc = '[C]laude [S]end selection' })
keymap('n', '<leader>cr', '<cmd>ClaudeCode --resume<CR>', { desc = '[C]laude [R]esume' })

-- Which-Key
require('which-key').setup()

-- Conform (formatter)
require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd', 'eslint_d' },
    typescript = { 'prettierd', 'eslint_d' },
    javascriptreact = { 'prettierd', 'eslint_d' },
    typescriptreact = { 'prettierd', 'eslint_d' },
    json = { 'prettierd' },
    yaml = { 'prettierd' },
    markdown = { 'prettierd' },
    css = { 'prettierd' },
    html = { 'prettierd' },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
}
keymap({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = '[F]ormat buffer' })

-- Trouble
require('trouble').setup()
keymap('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', { desc = 'Diagnostics (Trouble)' })
keymap('n', '<leader>xb', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', { desc = 'Buffer diagnostics (Trouble)' })
keymap('n', '<leader>xs', '<cmd>Trouble symbols toggle focus=false<CR>', { desc = 'Symbols (Trouble)' })
keymap('n', '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<CR>', { desc = 'LSP refs (Trouble)' })
keymap('n', '<leader>xq', '<cmd>Trouble qflist toggle<CR>', { desc = 'Quickfix (Trouble)' })
keymap('n', '<leader>xt', '<cmd>Trouble todo toggle<CR>', { desc = 'Todo (Trouble)' })

-- Render Markdown
require('render-markdown').setup()

-- Copilot
require('copilot').setup {
  suggestion = { enabled = false },
  panel = { enabled = false },
}
require('copilot_cmp').setup()

-- Fidget (LSP progress)
require('fidget').setup {}

-- ============================================================================
-- LSP (nvim 0.11+ native config)
-- ============================================================================
local capabilities = vim.tbl_deep_extend(
  'force',
  vim.lsp.protocol.make_client_capabilities(),
  require('cmp_nvim_lsp').default_capabilities()
)

-- LSP server configurations
vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  settings = {
    Lua = {
      completion = { callSnippet = 'Replace' },
    },
  },
})

vim.lsp.config('pyright', { capabilities = capabilities })
vim.lsp.config('ts_ls', { capabilities = capabilities })
vim.lsp.config('tailwindcss', { capabilities = capabilities })
vim.lsp.config('html', { capabilities = capabilities })
vim.lsp.config('cssls', { capabilities = capabilities })
vim.lsp.config('eslint', { capabilities = capabilities })
vim.lsp.config('nil_ls', { capabilities = capabilities })

-- rust-analyzer is managed by rustaceanvim, not lspconfig
vim.g.rustaceanvim = {
  server = {
    capabilities = capabilities,
    default_settings = {
      ['rust-analyzer'] = {
        inlayHints = {
          chainingHints = { enable = true },
          typeHints = { enable = true },
          parameterHints = { enable = true },
        },
      },
    },
  },
}

-- Enable all configured LSPs (rust handled by rustaceanvim)
vim.lsp.enable({ 'lua_ls', 'pyright', 'ts_ls', 'tailwindcss', 'html', 'cssls', 'eslint', 'nil_ls' })

-- LSP keymaps on attach
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      keymap('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', builtin.lsp_definitions, 'Goto Definition')
    map('gr', builtin.lsp_references, 'Goto References')
    map('gI', builtin.lsp_implementations, 'Goto Implementation')
    map('<leader>D', builtin.lsp_type_definitions, 'Type Definition')
    map('<leader>ds', builtin.lsp_document_symbols, 'Document Symbols')
    map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, 'Workspace Symbols')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('gD', vim.lsp.buf.declaration, 'Goto Declaration')

    if vim.lsp.inlay_hint then
      map('<leader>ih', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, 'Toggle Inlay Hints')
    end
  end,
})

-- ============================================================================
-- COMPLETION
-- ============================================================================
local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'

luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  formatting = {
    expandable_indicator = true,
    format = lspkind.cmp_format {
      mode = 'symbol_text',
      maxwidth = 50,
      ellipsis_char = '...',
      symbol_map = { Copilot = '' },
    },
  },
  completion = { completeopt = 'menu,menuone,noinsert' },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-y>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true },
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<C-l>'] = cmp.mapping(function()
      if luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      end
    end, { 'i', 's' }),
    ['<C-h>'] = cmp.mapping(function()
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'copilot' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'path' },
    { name = 'buffer' },
  },
}

-- SQL completion
cmp.setup.filetype({ 'sql' }, {
  sources = {
    { name = 'vim-dadbod-completion' },
    { name = 'buffer' },
  },
})

-- ============================================================================
-- TREESITTER
-- ============================================================================
-- With nixCats, grammars are managed by nix
-- Enable treesitter highlighting and indentation for all buffers
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
