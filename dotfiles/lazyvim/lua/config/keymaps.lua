-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- =============================================
-- HJKL to JKL; Navigation Remapping
-- =============================================

-- Core navigation remapping (Normal, Visual, and Operator-pending modes)
local nav_modes = { "n", "v", "o" }

-- Basic movement: h -> j, j -> k, k -> l, l -> ;
for _, mode in ipairs(nav_modes) do
  vim.keymap.set(mode, "j", "h", { desc = "Move left" })      -- j replaces h (left)
  vim.keymap.set(mode, "k", "j", { desc = "Move down" })      -- k replaces j (down) 
  vim.keymap.set(mode, "l", "k", { desc = "Move up" })        -- l replaces k (up)
  vim.keymap.set(mode, ";", "l", { desc = "Move right" })     -- ; replaces l (right)
end

-- =============================================
-- Conflict Resolution (Fallbacks Only)
-- =============================================

-- Buffer/Window navigation (use Alt for window switching)
vim.keymap.set("n", "<A-j>", "<C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<A-k>", "<C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<A-l>", "<C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<A-;>", "<C-l>", { desc = "Go to right window" })

-- Buffer switching (use Ctrl+Alt to avoid conflicts)
vim.keymap.set("n", "<C-A-k>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-A-l>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Join lines (preserve J functionality with Alt)
vim.keymap.set("n", "<A-J>", "J", { desc = "Join lines" })

-- =============================================
-- Insert Mode Navigation
-- =============================================

-- Insert mode cursor movement (Ctrl + navigation)
vim.keymap.set("i", "<C-j>", "<Left>", { desc = "Move left in insert mode" })
vim.keymap.set("i", "<C-k>", "<Down>", { desc = "Move down in insert mode" })
vim.keymap.set("i", "<C-l>", "<Up>", { desc = "Move up in insert mode" })
vim.keymap.set("i", "<C-;>", "<Right>", { desc = "Move right in insert mode" })

-- =============================================
-- Command Line Mode Navigation
-- =============================================

-- Command line cursor movement
vim.keymap.set("c", "<C-j>", "<Left>", { desc = "Move left in command line" })
vim.keymap.set("c", "<C-;>", "<Right>", { desc = "Move right in command line" })

-- Completion navigation with arrows (preserved from original)
vim.keymap.set("i", "<C-Down>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Down>"
  end
end, { expr = true, desc = "Navigate down in completion menu" })

vim.keymap.set("i", "<C-Up>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<Up>"
  end
end, { expr = true, desc = "Navigate up in completion menu" })
