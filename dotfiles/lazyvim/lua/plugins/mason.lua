-- Central Mason configuration for LSP servers, formatters, and linters
-- Manages all tool installations to avoid conflicts and ensure consistency

return {
  -- Main Mason plugin for managing external tools
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        -- LSP servers
        "gopls",              -- Go language server
        "nil",                -- Nix language server  
        "css-lsp",            -- CSS/JSON language server
        "dockerfile-language-server", -- Docker language server
        "docker-compose-language-service", -- Docker Compose LSP
        "jdtls",              -- Java language server
        
        -- Formatters
        "goimports",          -- Go imports formatter
        "gofumpt",            -- Go strict formatter
        "prettier",           -- JavaScript/JSON/YAML formatter
        "alejandra",          -- Nix formatter
        "stylua",             -- Lua formatter
        "shfmt",              -- Shell script formatter
        
        -- Linters
        "hadolint",           -- Dockerfile linter
        
        -- Debug adapters (Java specific)
        "java-debug-adapter", -- Java debug adapter
        "java-test",          -- Java test adapter
      },
    },
  },
  
  -- Mason-LSPConfig integration for automatic server setup
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "gopls",
        "nil", 
        "css-lsp",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "jdtls",
      },
      -- Automatic server setup for basic configurations
      automatic_installation = true,
    },
  },
}