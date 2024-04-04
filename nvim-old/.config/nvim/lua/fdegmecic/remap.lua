vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])

vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.dotfiles/nvim/.config/nvim/lua/theprimeagen/packer.lua<CR>");

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

vim.keymap.set("n", "<leader>l", function()
local file_path = vim.fn.expand("%:p")
    local file_name = vim.fn.fnamemodify(file_path, ":t:r")

    local original_window = vim.api.nvim_get_current_win()
    local original_width = vim.api.nvim_win_get_width(original_window)
    local new_width = math.floor(original_width * 0.4)
    vim.cmd("rightbelow " .. new_width .. "vnew")    

    local cmd = "bacon test -- -- -p " ..file_name 
    vim.fn.termopen(cmd)
    vim.api.nvim_set_current_win(original_window)
end)

vim.keymap.set("n", "<leader>m", function()
    vim.cmd("wincmd l")
    vim.cmd("q")
end)

vim.keymap.set("n", "<leader>n", function()
    local file_path = vim.fn.expand("%:p")
    local file_name = vim.fn.fnamemodify(file_path, ":t:r")

    local original_window = vim.api.nvim_get_current_win()
    local original_width = vim.api.nvim_win_get_width(original_window)
    local new_width = math.floor(original_width * 0.4)

    vim.cmd("rightbelow " .. new_width .. "vnew")

    local cmd = "cargo test --color=always " ..file_name .. "::test -- --show-output"

    vim.fn.termopen(cmd)
    vim.api.nvim_set_current_win(original_window)
     
end)
