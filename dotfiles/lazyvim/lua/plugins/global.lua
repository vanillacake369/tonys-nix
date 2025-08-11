-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- Colorscheme :: material.nvim
  {
    "marko-cerovac/material.nvim",
    name = "material",
    priority = 1000,
    lazy = false,
    config = function()
      vim.g.material_style = "darker"
      require("material").setup({})
      vim.cmd("colorscheme material")
    end,
  },

  -- Configure LazyVim
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "material",
    },
  },

  -- Trouble config
  {
    "folke/trouble.nvim",
    opts = {
      -- Configure Trouble with jkl; navigation
      modes = {
        diagnostics = {
          keys = {
            ["k"] = "next",           -- k = down/next item
            ["l"] = "prev",           -- l = up/previous item
            ["j"] = "fold_close",     -- j = fold close (left-like action)
            [";"] = "fold_open",      -- ; = fold open (right-like action)
            
            -- Additional navigation with Ctrl combinations
            ["<C-k>"] = { "jump", mode = "split" },    -- Ctrl+k = jump in split
            ["<C-l>"] = { "jump", mode = "vsplit" },   -- Ctrl+l = jump in vsplit
            ["<C-j>"] = "fold_close_all",              -- Ctrl+j = close all folds
            ["<C-;>"] = "fold_open_all",               -- Ctrl+; = open all folds
          },
        },
        symbols = {
          keys = {
            ["k"] = "next",           -- k = down/next symbol
            ["l"] = "prev",           -- l = up/previous symbol  
            ["j"] = "fold_close",     -- j = collapse symbol
            [";"] = "fold_open",      -- ; = expand symbol
          },
        },
        lsp = {
          keys = {
            ["k"] = "next",           -- k = next reference
            ["l"] = "prev",           -- l = previous reference
            ["j"] = "fold_close",     -- j = fold close
            [";"] = "fold_open",      -- ; = fold open
          },
        },
        qflist = {
          keys = {
            ["k"] = "next",           -- k = next quickfix item
            ["l"] = "prev",           -- l = previous quickfix item
          },
        },
        loclist = {
          keys = {
            ["k"] = "next",           -- k = next location item  
            ["l"] = "prev",           -- l = previous location item
          },
        },
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  -- Multi cursor
  {
    "mg979/vim-visual-multi",
    init = function()
      -- Configure vim-visual-multi to use jkl; navigation
      -- These settings must be configured before the plugin loads
      vim.g.VM_maps = {
        -- Basic movement (following jkl; pattern)
        ["Move Left"] = "j",        -- j = move left
        ["Move Down"] = "k",        -- k = move down  
        ["Move Up"] = "l",          -- l = move up
        ["Move Right"] = ";",       -- ; = move right
        
        -- Word movement
        ["Word Left"] = "J",        -- J = word left
        ["Word Right"] = ":",       -- : = word right (Shift+;)
        
        -- Selection extension
        ["Extend Left"] = "<S-j>",  -- Shift+j = extend selection left
        ["Extend Down"] = "<S-k>",  -- Shift+k = extend selection down
        ["Extend Up"] = "<S-l>",    -- Shift+l = extend selection up  
        ["Extend Right"] = "<S-;>", -- Shift+; = extend selection right
        
        -- Multi-cursor specific actions
        ["Add Cursor Down"] = "<C-k>",       -- Ctrl+k = add cursor down
        ["Add Cursor Up"] = "<C-l>",         -- Ctrl+l = add cursor up
        ["Select Cursor Down"] = "<C-A-k>",  -- Ctrl+Alt+k = select cursor down
        ["Select Cursor Up"] = "<C-A-l>",    -- Ctrl+Alt+l = select cursor up
        
        -- Pattern selection
        ["Select All Words"] = "<C-A-a>",    -- Ctrl+Alt+a = select all words
        ["Select Next"] = "<C-A-n>",         -- Ctrl+Alt+n = select next occurrence
        
        -- Navigation between cursors
        ["Goto Next"] = "]]",                -- ]] = go to next cursor
        ["Goto Prev"] = "[[",                -- [[ = go to previous cursor
        
        -- Visual Multi specific  
        ["Switch Mode"] = "<Tab>",           -- Tab = switch between cursor/extend mode
        ["Toggle Mappings"] = "<C-A-m>",     -- Ctrl+Alt+m = toggle mappings
      }
      
      -- Additional VM settings for better jkl; integration
      vim.g.VM_leader = "\\"                 -- Use backslash as VM leader
      vim.g.VM_theme = "iceblue"            -- Nice visual theme
      vim.g.VM_highlight_matches = "underline" -- Highlight matches
    end,
  },

  -- Justfile syntax
  {
    "NoahTheDuke/vim-just",
    ft = { "just" },
  },

  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")
      table.insert(opts.sources, { name = "emoji" })
      
      -- Enhanced keymaps with jkl; navigation
      opts.mapping = cmp.mapping.preset.insert({
        -- jkl; navigation (using Ctrl to avoid conflicts with typing)
        ["<C-k>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), -- k = down
        ["<C-l>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), -- l = up
        ["<C-j>"] = cmp.mapping.scroll_docs(-4),  -- j = scroll docs left/up
        ["<C-;>"] = cmp.mapping.scroll_docs(4),   -- ; = scroll docs right/down
        
        -- Fast navigation with Ctrl+Alt
        ["<C-A-k>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 5 do cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert }) end
          else
            fallback()
          end
        end, { "i", "s" }),  -- Jump 5 items down
        
        ["<C-A-l>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 5 do cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert }) end
          else
            fallback()
          end
        end, { "i", "s" }),  -- Jump 5 items up
        
        -- Traditional fallbacks (preserved for compatibility)
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        
        -- Action mappings
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Esc>"] = cmp.mapping.abort(),
        ["<C-Space>"] = cmp.mapping.complete(),
        
        -- Additional functionality
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

  -- change some telescope options and a keymap to browse plugin files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            -- Use jkl; navigation in insert mode (Telescope prompt)
            ["<C-k>"] = "move_selection_next",        -- k = down
            ["<C-l>"] = "move_selection_previous",    -- l = up
            ["<C-j>"] = "move_selection_worse",       -- j = left (worse match)
            ["<C-;>"] = "move_selection_better",      -- ; = right (better match)
            
            -- Preview window navigation
            ["<C-A-k>"] = "preview_scrolling_down",   -- Ctrl+Alt+k = scroll preview down
            ["<C-A-l>"] = "preview_scrolling_up",     -- Ctrl+Alt+l = scroll preview up
            ["<C-A-j>"] = "preview_scrolling_left",   -- Ctrl+Alt+j = scroll preview left
            ["<C-A-;>"] = "preview_scrolling_right",  -- Ctrl+Alt+; = scroll preview right
            
            -- Results window navigation (Ctrl combinations for fine control)
            ["<C-A-o>"] = "results_scrolling_down",   -- Scroll results down
            ["<C-A-i>"] = "results_scrolling_up",     -- Scroll results up
          },
          n = {
            -- Normal mode navigation in Telescope (when not in prompt)
            ["k"] = "move_selection_next",            -- k = down  
            ["l"] = "move_selection_previous",        -- l = up
            ["j"] = "move_selection_worse",           -- j = left (worse match)
            [";"] = "move_selection_better",          -- ; = right (better match)
            
            -- Preview navigation in normal mode
            ["<C-k>"] = "preview_scrolling_down",     -- Ctrl+k = scroll preview down
            ["<C-l>"] = "preview_scrolling_up",       -- Ctrl+l = scroll preview up
            ["<C-j>"] = "preview_scrolling_left",     -- Ctrl+j = scroll preview left
            ["<C-;>"] = "preview_scrolling_right",    -- Ctrl+; = scroll preview right
          },
        },
      },
    },
  },


  -- the opts function can also be used to change the default opts:
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          return "😄"
        end,
      })
    end,
  },

  -- Neo-tree file explorer with jkl; navigation
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        mappings = {
          -- jkl; navigation mappings for Neo-tree
          ["j"] = "focus_preview",           -- j = focus left (preview)
          ["k"] = "next_sibling",            -- k = move down
          ["l"] = "prev_sibling",            -- l = move up  
          [";"] = "open",                    -- ; = open (move right into)
          
          -- Additional jkl; combinations
          ["J"] = "navigate_up",             -- J = go up directory (shift+j)
          ["K"] = { "scroll_down", nowait = false, noremap = true }, -- K = scroll down (shift+k)
          ["L"] = { "scroll_up", nowait = false, noremap = true },   -- L = scroll up (shift+l)
          [":"] = "open_vsplit",             -- : = open in vertical split (shift+;)
          
          -- Preserve essential functionality with Ctrl combinations
          ["<C-j>"] = "close_node",          -- Ctrl+j = close/collapse
          ["<C-k>"] = "next_sibling",        -- Ctrl+k = next sibling
          ["<C-l>"] = "prev_sibling",        -- Ctrl+l = prev sibling  
          ["<C-;>"] = "open_with_window_picker", -- Ctrl+; = open with window picker
          
          -- File operations (preserve with Alt combinations)
          ["<A-j>"] = "cut_to_clipboard",    -- Alt+j = cut
          ["<A-k>"] = "copy_to_clipboard",   -- Alt+k = copy
          ["<A-l>"] = "paste_from_clipboard", -- Alt+l = paste
          ["<A-;>"] = "delete",              -- Alt+; = delete
          
          -- Quick actions
          ["o"] = "open",
          ["<CR>"] = "open", 
          ["<2-LeftMouse>"] = "open",
          ["t"] = "open_tabnew",
          ["s"] = "open_split",
          ["v"] = "open_vsplit",
          ["w"] = "open_with_window_picker",
          ["C"] = "close_node",
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",
          ["a"] = "add",
          ["A"] = "add_directory",
          ["d"] = "delete",
          ["r"] = "rename",
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["c"] = "copy",
          ["m"] = "move",
          ["q"] = "close_window",
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["<"] = "navigate_up",
          ["."] = "set_root",
          ["H"] = "toggle_hidden",
          ["/"] = "fuzzy_finder",
          ["D"] = "fuzzy_finder_directory",
          ["#"] = "fuzzy_sorter",
          ["f"] = "filter_on_submit",
          ["<C-x>"] = "clear_filter",
          ["[g"] = "prev_git_modified",
          ["]g"] = "next_git_modified",
          ["i"] = "show_file_details",
          ["<bs>"] = "navigate_up",
          ["<space>"] = "toggle_node",
        },
      },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
    },
  },

  -- Conform.nvim formatter
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" },
        go = { "goimports", "gofumpt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      -- Debug: Ensure alejandra is available
      formatters = {
        alejandra = {
          command = "alejandra",
          args = { "--quiet" },
          stdin = true,
        },
      },
    },
  },
}
