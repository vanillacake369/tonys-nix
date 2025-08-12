-- ~/.config/nvim/lua/plugins/navigation.lua
-- Navigation and search plugins

return {
  -- Telescope with custom jkl; navigation
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<C-k>"] = "move_selection_next",
            ["<C-l>"] = "move_selection_previous",
            ["<C-j>"] = "move_selection_worse",
            ["<C-;>"] = "move_selection_better",
            ["<C-A-k>"] = "preview_scrolling_down",
            ["<C-A-l>"] = "preview_scrolling_up",
            ["<C-A-j>"] = "preview_scrolling_left",
            ["<C-A-;>"] = "preview_scrolling_right",
            ["<C-A-o>"] = "results_scrolling_down",
            ["<C-A-i>"] = "results_scrolling_up",
          },
          n = {
            ["k"] = "move_selection_next",
            ["l"] = "move_selection_previous",
            ["j"] = "move_selection_worse",
            [";"] = "move_selection_better",
            ["<C-k>"] = "preview_scrolling_down",
            ["<C-l>"] = "preview_scrolling_up",
            ["<C-j>"] = "preview_scrolling_left",
            ["<C-;>"] = "preview_scrolling_right",
          },
        },
      },
    },
  },
}