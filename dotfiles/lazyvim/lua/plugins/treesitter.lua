-- Consolidated Treesitter Configuration
-- All treesitter parsers consolidated from individual language files
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Base languages
        "bash",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "vim",
        "yaml",
        -- Development languages
        "nix",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "java",
        "dockerfile",
        -- Infrastructure
        "helm",
        -- Git-related
        "git_config",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "gitattributes",
      },
    },
  },
}

