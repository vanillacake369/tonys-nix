-- Central Mason configuration for LSP servers, formatters, and linters
-- Manages all tool installations to avoid conflicts and ensure consistency

return {
  -- Main Mason plugin for managing external tools
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        -- LSP servers
        "gopls",                            -- Go language server
        "dockerfile-language-server",       -- Docker language server
        "docker-compose-language-service",  -- Docker Compose language server
        "jdtls",                            -- Java language server
        -- Formatters
        "goimports",                        -- Go imports formatter
        "gofumpt",                          -- Go strict formatter
        "prettier",                         -- JavaScript/JSON/YAML formatter
        "stylua",                           -- Lua formatter
        "shfmt",                            -- Shell script formatter
        -- Debug adapters (Java specific)
        "java-debug-adapter", -- Java debug adapter
        "java-test", -- Java test adapter
      },
    },
  },

  -- Mason-LSPConfig integration for automatic server setup
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "gopls",
        "jdtls",
      },
      -- Automatic server setup for basic configurations
      automatic_installation = true,
    },
  },

  -- LSP configuration for Nix-installed tools
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Configure nixd (installed via Nix)
        nixd = {
          cmd = { "nixd" },
          settings = {
            nixd = {
              formatting = {
                command = { "alejandra" },
              },
              options = {
                enable = true,
                target = {
                  installable = ".#homeConfigurations.hm-aarch64-darwin.activationPackage",
                },
              },
            },
          },
        },
      },
    },
  },
}
