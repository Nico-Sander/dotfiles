vim.pack.add({
  "https://github.com/folke/tokyonight.nvim", -- TokyoNight Colorscheme
  "https://github.com/nvim-treesitter/nvim-treesitter", -- Parser installer (highlighting itself is built in)
})

----------------------------------------------------------------------------------
-- Tokyonight colorscheme with custom colors to match wezterm
----------------------------------------------------------------------------------
require("tokyonight").setup({
  style = "night",
  on_colors = function(colors)
    colors.bg = "#15161a"
  end,
  -- hl: every highlight group tokyonight is about to apply (hl.Comment, ...)
  -- c:  the palette, including the on_colors changes above (c.blue, c.comment, ...)
  on_highlights = function(hl, c)
    hl.StatusLine.fg = c.yellow
    hl.WinSeparator = { fg = c.yellow } -- split lines (horizontal too, with laststatus=3)
  end,
})

vim.cmd.colorscheme("tokyonight")

----------------------------------------------------------------------------------
-- Treesitter
----------------------------------------------------------------------------------
require("nvim-treesitter").install {
  "rust",
}

