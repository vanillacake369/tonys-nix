-- Docker language support configuration
-- Provides LSP support for Dockerfile and docker-compose files

return {
  -- LSP Configuration for Docker
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
