-- Java language support configuration
-- Provides LSP support with JDTLS and debug/test adapters

return {
  -- LSP Configuration for Java
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },
}
