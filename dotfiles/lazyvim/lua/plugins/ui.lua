-- ~/.config/nvim/lua/plugins/ui.lua
-- UI enhancement plugins

return {
  -- Trouble.nvim for better diagnostics UI with jkl; navigation
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        diagnostics = {
          keys = {
            ["k"] = "next",
            ["l"] = "prev",
            ["j"] = "fold_close",
            [";"] = "fold_open",
            ["<C-k>"] = { "jump", mode = "split" },
            ["<C-l>"] = { "jump", mode = "vsplit" },
            ["<C-j>"] = "fold_close_all",
            ["<C-;>"] = "fold_open_all",
          },
        },
        symbols = { keys = { ["k"] = "next", ["l"] = "prev", ["j"] = "fold_close", [";"] = "fold_open" } },
        lsp = { keys = { ["k"] = "next", ["l"] = "prev", ["j"] = "fold_close", [";"] = "fold_open" } },
        qflist = { keys = { ["k"] = "next", ["l"] = "prev" } },
        loclist = { keys = { ["k"] = "next", ["l"] = "prev" } },
      },
    },
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Defs/Refs (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },

  -- Lualine status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          return "😄"
        end,
      })
    end,
  },
}