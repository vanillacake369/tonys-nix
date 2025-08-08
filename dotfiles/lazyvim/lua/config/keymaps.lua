-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Completion navigation with arrows
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
