-- ~/.config/nvim/lua/plugins/formatting.lua
-- Code formatting plugins

return {
  -- Conform for code formatting
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}