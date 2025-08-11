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
-- Conflict Resolution (Fallbacks)
-- =============================================

-- Buffer/Window navigation (use Alt for window switching)
vim.keymap.set("n", "<A-j>", "<C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<A-k>", "<C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<A-l>", "<C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<A-;>", "<C-l>", { desc = "Go to right window" })

-- Buffer switching (use Ctrl+Alt to avoid conflicts)
vim.keymap.set("n", "<C-A-k>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-A-l>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Tab navigation (Ctrl+Alt combinations)
vim.keymap.set("n", "<C-A-o>", ":tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<C-A-i>", ":tabprevious<CR>", { desc = "Previous tab" })

-- Join lines (preserve J functionality with Alt)
vim.keymap.set("n", "<A-J>", "J", { desc = "Join lines" })

-- Search navigation (preserve n/N functionality)
vim.keymap.set("n", "<A-n>", "n", { desc = "Next search result" })
vim.keymap.set("n", "<A-N>", "N", { desc = "Previous search result" })

-- =============================================
-- Insert Mode Navigation
-- =============================================

-- Insert mode cursor movement (Ctrl + navigation)
vim.keymap.set("i", "<C-j>", "<Left>", { desc = "Move left in insert mode" })
vim.keymap.set("i", "<C-k>", "<Down>", { desc = "Move down in insert mode" })
vim.keymap.set("i", "<C-l>", "<Up>", { desc = "Move up in insert mode" })
vim.keymap.set("i", "<C-;>", "<Right>", { desc = "Move right in insert mode" })

-- Word movement in insert mode
vim.keymap.set("i", "<C-A-j>", "<C-Left>", { desc = "Move word left in insert mode" })
vim.keymap.set("i", "<C-A-;>", "<C-Right>", { desc = "Move word right in insert mode" })

-- =============================================
-- Command Line Mode Navigation
-- =============================================

-- Command line cursor movement
vim.keymap.set("c", "<C-j>", "<Left>", { desc = "Move left in command line" })
vim.keymap.set("c", "<C-;>", "<Right>", { desc = "Move right in command line" })
vim.keymap.set("c", "<C-A-j>", "<S-Left>", { desc = "Move word left in command line" })
vim.keymap.set("c", "<C-A-;>", "<S-Right>", { desc = "Move word right in command line" })

-- Command line history
vim.keymap.set("c", "<C-l>", "<Up>", { desc = "Previous command" })
vim.keymap.set("c", "<C-k>", "<Down>", { desc = "Next command" })

-- =============================================
-- Terminal Mode Navigation
-- =============================================

-- Terminal mode navigation (Ctrl+Alt combinations to avoid conflicts)
vim.keymap.set("t", "<C-A-j>", "<C-\\><C-n><C-w>h", { desc = "Terminal: Go to left window" })
vim.keymap.set("t", "<C-A-k>", "<C-\\><C-n><C-w>j", { desc = "Terminal: Go to lower window" })
vim.keymap.set("t", "<C-A-l>", "<C-\\><C-n><C-w>k", { desc = "Terminal: Go to upper window" })
vim.keymap.set("t", "<C-A-;>", "<C-\\><C-n><C-w>l", { desc = "Terminal: Go to right window" })

-- Terminal escape
vim.keymap.set("t", "<C-A-[>", "<C-\\><C-n>", { desc = "Terminal: Exit terminal mode" })

-- =============================================
-- Visual Mode Enhancements
-- =============================================

-- Visual block mode improvements
vim.keymap.set("v", "<C-j>", "<", { desc = "Indent left" })
vim.keymap.set("v", "<C-;>", ">", { desc = "Indent right" })
vim.keymap.set("v", "<C-l>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "<C-k>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

-- =============================================
-- Plugin-Specific Navigation Overrides
-- =============================================

-- These will be set up via autocmds to ensure they apply in plugin contexts
-- Setup function for plugin-specific mappings
local function setup_plugin_navigation()
  -- Telescope mappings (applied when Telescope is active)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "TelescopePrompt",
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      -- Use Ctrl combinations in Telescope to avoid conflicts with filtering
      vim.keymap.set("i", "<C-k>", "<Down>", opts)
      vim.keymap.set("i", "<C-l>", "<Up>", opts)
      vim.keymap.set("i", "<C-j>", "<Left>", opts)
      vim.keymap.set("i", "<C-;>", "<Right>", opts)
      
      -- Preview window navigation
      vim.keymap.set("i", "<C-A-k>", require("telescope.actions").preview_scrolling_down, opts)
      vim.keymap.set("i", "<C-A-l>", require("telescope.actions").preview_scrolling_up, opts)
    end,
  })
  
  -- Trouble mappings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "trouble",
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      vim.keymap.set("n", "k", "j", opts)  -- k = down
      vim.keymap.set("n", "l", "k", opts)  -- l = up  
      vim.keymap.set("n", "j", "<C-w>h", opts)  -- j = focus left
      vim.keymap.set("n", ";", "<C-w>l", opts)  -- ; = focus right
    end,
  })
  
  -- Neo-tree mappings (if using LazyVim default)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      vim.keymap.set("n", "k", "j", opts)  -- k = down
      vim.keymap.set("n", "l", "k", opts)  -- l = up
      vim.keymap.set("n", "j", "h", opts)  -- j = collapse
      vim.keymap.set("n", ";", "l", opts)  -- ; = expand
    end,
  })
  
  -- Quickfix and location list
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "qf", "loclist" },
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      vim.keymap.set("n", "k", "j", opts)  -- k = down
      vim.keymap.set("n", "l", "k", opts)  -- l = up
    end,
  })
  
  -- Help files navigation
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "help",
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      vim.keymap.set("n", "k", "j", opts)  -- k = down
      vim.keymap.set("n", "l", "k", opts)  -- l = up
      vim.keymap.set("n", "j", "h", opts)  -- j = left
      vim.keymap.set("n", ";", "l", opts)  -- ; = right
    end,
  })
  
  -- Git commit messages
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "gitcommit", "gitrebase" },
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      
      vim.keymap.set("n", "k", "j", opts)  -- k = down
      vim.keymap.set("n", "l", "k", opts)  -- l = up
    end,
  })
end

-- Set up plugin navigation on VimEnter to ensure all plugins are loaded
vim.api.nvim_create_autocmd("VimEnter", {
  callback = setup_plugin_navigation,
})

-- =============================================
-- Completion Menu Navigation
-- =============================================

-- Enhanced completion navigation (works with nvim-cmp)
vim.keymap.set("i", "<C-k>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Down>"
  end
end, { expr = true, desc = "Navigate down in completion menu" })

vim.keymap.set("i", "<C-l>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<Up>"
  end
end, { expr = true, desc = "Navigate up in completion menu" })

-- Additional completion controls
vim.keymap.set("i", "<C-A-k>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n><C-n><C-n><C-n><C-n>"  -- Jump 5 items down
  else
    return "<C-A-k>"
  end
end, { expr = true, desc = "Jump down in completion menu" })

vim.keymap.set("i", "<C-A-l>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p><C-p><C-p><C-p><C-p>"  -- Jump 5 items up
  else
    return "<C-A-l>"
  end
end, { expr = true, desc = "Jump up in completion menu" })
