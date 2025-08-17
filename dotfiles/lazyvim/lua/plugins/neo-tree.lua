-- ~/.config/nvim/lua/plugins/neo-tree.lua
-- Neo-tree file explorer with jkl; navigation

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true, -- Close Neo-tree if it's the last window
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      window = {
        mappings = {
          -- jkl; navigation - keep j/k as normal cursor movement
          -- only override l and ; for horizontal actions
          ["l"] = "open",        -- right: open/expand
          [";"] = "close_node",  -- left: close/collapse
          
          -- disable h to avoid conflicts
          ["h"] = "none",

          -- keep some defaults
          ["<space>"] = "toggle_node",
          ["<cr>"] = "open",
          ["q"] = "close_window", 
          ["R"] = "refresh",
        },
      },
      filesystem = {
        window = {
          mappings = {
            -- same overrides for filesystem
            ["l"] = "open",
            [";"] = "close_node",
            ["h"] = "none",

            -- keep filesystem-specific stuff
            ["/"] = "fuzzy_finder",
            ["f"] = "filter_on_submit",
            ["<c-x>"] = "clear_filter",
          },
        },
      },
    },
  },
}

