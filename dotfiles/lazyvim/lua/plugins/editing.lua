-- ~/.config/nvim/lua/plugins/editing.lua
-- Editing enhancement plugins

return {
  -- Multi-cursor support with jkl; navigation
  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ["Move Left"] = "j",
        ["Move Down"] = "k",
        ["Move Up"] = "l",
        ["Move Right"] = ";",
        ["Word Left"] = "J",
        ["Word Right"] = ":",
        ["Extend Left"] = "<S-j>",
        ["Extend Down"] = "<S-k>",
        ["Extend Up"] = "<S-l>",
        ["Extend Right"] = "<S-;>",
        ["Add Cursor Down"] = "<C-k>",
        ["Add Cursor Up"] = "<C-l>",
        ["Select Cursor Down"] = "<C-A-k>",
        ["Select Cursor Up"] = "<C-A-l>",
        ["Select All Words"] = "<C-A-a>",
        ["Select Next"] = "<C-A-n>",
        ["Goto Next"] = "]]",
        ["Goto Prev"] = "[[",
        ["Switch Mode"] = "<Tab>",
        ["Toggle Mappings"] = "<C-A-m>",
      }
      vim.g.VM_leader = "\\"
      vim.g.VM_theme = "iceblue"
      vim.g.VM_highlight_matches = "underline"
    end,
  },

  -- nvim-cmp with custom jkl; navigation and emoji support
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    opts = function(_, opts)
      local cmp = require("cmp")
      table.insert(opts.sources, { name = "emoji" })
      opts.mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-l>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-j>"] = cmp.mapping.scroll_docs(-4),
        ["<C-;>"] = cmp.mapping.scroll_docs(4),
        ["<C-A-k>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 5 do
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
            end
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-A-l>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 5 do
              cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
            end
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Esc>"] = cmp.mapping.abort(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },
}

