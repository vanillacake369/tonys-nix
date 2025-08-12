return {
  -- Install alejandra automatically
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "alejandra",
      },
      run_on_start = true,
      start_delay = 3000, -- wait 3s so Mason is ready
      auto_update = false,
    },
  },

  -- Configure Conform to use alejandra
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        nix = { "alejandra" },
      })
    end,
  },
}
