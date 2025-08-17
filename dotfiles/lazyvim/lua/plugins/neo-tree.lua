return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        mappings = {
          -- Override hjkl to jkl;
          ["j"] = "close_node",
          ["k"] = "next_sibling",
          ["l"] = "prev_sibling",
          [";"] = "open",
        },
      },
    },
  },
}

