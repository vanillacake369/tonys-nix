-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "vim",
        "yaml",
        "nix",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "java",
        "dockerfile",
      },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    ft = { "nix" },
    opts = {
      servers = {
        nixd = {
          cmd = { "nixd" },
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
              },
              formatting = {
                command = { "alejandra" },
              },
              options = {
                nixos = {
                  expr = "let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.limjihoon.options",
                },
                home_manager = {
                  expr = "let flake = builtins.getFlake(toString ./.); in flake.homeConfigurations.limjihoon.options",
                },
              },
            },
          },
        },
      },
    },
  },

  -- Formatter :: conform
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        go = { "goimports", "gofumpt" },
      },
    },
  },
}
