-- ~/.config/nvim/lua/plugins/colorscheme.lua
-- Theme and colorscheme configuration

return {
  -- Material theme
  {
    "marko-cerovac/material.nvim",
    name = "material",
    priority = 1000,
    lazy = false,
    config = function()
      vim.g.material_style = "darker"
      require("material").setup({})
    end,
  },

  -- Configure LazyVim to use material colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material",
    },
  },
}