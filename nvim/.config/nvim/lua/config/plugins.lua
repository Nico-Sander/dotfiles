vim.pack.add({
  "https://github.com/folke/tokyonight.nvim",                                          -- TokyoNight Colorscheme
  "https://github.com/nvim-treesitter/nvim-treesitter",                                -- Parser installer (highlighting itself is built in)
  "https://github.com/nvim-mini/mini.nvim",                                            -- Collection of modules (files, surround, pairs, diff, ...)
  "https://github.com/folke/snacks.nvim",                                              -- Picker, indent guides, vim.ui.input, smooth scrolling
  "https://github.com/stevearc/conform.nvim",                                          -- Formatting
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") }, -- Completions
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
    -- Inactive windows get a darker background (NormalNC: "not current"),
    -- nvim switches between Normal and NormalNC on focus change
    local inactive = "#111219"
    hl.NormalNC.bg = inactive
    hl.SignColumn.bg = c.none -- follow the window's bg instead of a fixed one
    -- Split lines (horizontal too, with laststatus=3). Without a bg they'd use
    -- Normal's, a bright strip next to the dimmed windows
    hl.WinSeparator = { fg = c.yellow, bg = inactive }
  end,
})

vim.cmd.colorscheme("tokyonight")

----------------------------------------------------------------------------------
-- Treesitter
----------------------------------------------------------------------------------
require("nvim-treesitter").install {
  "rust",
}

----------------------------------------------------------------------------------
-- Mini Files
----------------------------------------------------------------------------------
require("mini.files").setup({
  mappings = { -- Mappings only apply when plugin runs, so they stay defined here
    go_in = "L",
    go_in_plus = "<CR>",
    go_out = "-",
    go_out_plus = "H",
  },
})

----------------------------------------------------------------------------------
-- Mini Cmdline Completion
----------------------------------------------------------------------------------
-- require("mini.cmdline").setup()

----------------------------------------------------------------------------------
-- Mini Surround
----------------------------------------------------------------------------------
require("mini.surround").setup()
-- Default mappings
-- | `sa` | Add surrounding |
-- | `sd` | Delete surrounding |
-- | `sr` | Replace surrounding |

----------------------------------------------------------------------------------
-- Mini Pairs
----------------------------------------------------------------------------------
require("mini.pairs").setup()

----------------------------------------------------------------------------------
-- Mini Diff (Git)
----------------------------------------------------------------------------------
require("mini.diff").setup({
  view = {
    style = "sign",
    signs = {
      add = "|",
      change = "|",
      delete = "-",
    },
  },
})

----------------------------------------------------------------------------------
-- Mini Trailspace
----------------------------------------------------------------------------------
require("mini.trailspace").setup({})

----------------------------------------------------------------------------------
-- Snacks
----------------------------------------------------------------------------------
-- Only modules with enabled = true are active; the rest of snacks (explorer,
-- dashboard, ...) stays off. Snacks.rename (used by the mini.files autocmd in
-- autocmds.lua) has no config and is always available.
require("snacks").setup({
  -- Picker docs: :h snacks-picker, keys inside a picker: press ? while it's open.
  picker = {
    enabled = true,

    -- Per-source defaults (:h snacks-picker-sources). Both finders run rg:
    --   hidden  = true  adds --hidden     (dotfiles and dot-directories)
    --   ignored = true  adds --no-ignore  (files listed in .gitignore)
    -- .git itself is always excluded. Toggle both at runtime with the keys below.
    sources = {
      files = {
        hidden = true,
        ignored = true,
      },
      grep = {
        hidden = true,
        ignored = true,
      },
    },

    -- A picker consists of several windows, each with its own buffer-local keys
    -- (they exist only while the picker is open, so they live here and not in
    -- keys.lua):
    --
    --   input    the search field at the top. Opens in insert mode, because
    --            you start typing right away; Esc switches it to normal mode.
    --            Keys need mode = { "i", "n" } to work while typing.
    --   list     the results. You only get here explicitly: with the mouse or
    --            the cycle_win action (default Alt+w, which tmux takes). It's
    --            always in normal mode, so a plain action name is enough.
    --            Moving through results from the input (Ctrl+j/k) doesn't
    --            need the list window to have focus.
    --   preview  the file preview on the right (not configured here).
    --
    -- The same keys are set in both windows so they work wherever the cursor
    -- is. Alt instead of Shift: in the input window Shift+h would just type
    -- "H". Alt+h (snacks' default for hidden) is taken by tmux, hence Alt+.
    win = {
      input = {
        keys = {
          ["<a-.>"] = { "toggle_hidden", mode = { "i", "n" } },
          ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<a-.>"] = "toggle_hidden",
          ["<a-i>"] = "toggle_ignored",
        },
      },
    },
  },

  indent = {
    enabled = true,
    indent = {
      char = "|",
      only_scope = false,
      only_current = true,
    },
  },

  input = { -- floating window for vim.ui.input() prompts (LSP rename, ...), not the cmdline
    enabled = true,
  },

  scroll = { -- smooth scrolling
    enabled = true,
  },

  notifier = {
    enabled = true,
    timeout = 6000,
  },
})

----------------------------------------------------------------------------------
-- Conform Formatting
----------------------------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    -- for available formatters see :h conform-formatters
    python = { "ruff_organize_imports", "ruff_format" }, -- multiple formatters are run sequentially
    rust = { "rustfmt" },
    bash = { "shfmt" },
    sh = { "shfmt" },
  },

  -- If this is set, Conform will run the formatter on save.
  -- It will pass the table to conform.format().
  -- This can also be a function that returns the table.
  format_on_save = {
    -- I recommend these options. See :help conform.format for details.
    lsp_format = "fallback",
    timeout_ms = 500,
  },
})

----------------------------------------------------------------------------------
-- Blink Completions
----------------------------------------------------------------------------------
require("blink.cmp").setup({
  -- Completion config for Buffer
  keymap = { preset = "default" },
  completion = {
    documentation = { auto_show = true },
    ghost_text = { enabled = true },
    list = { selection = { preselect = false, auto_insert = false } },
  },
  signature = { enabled = true },

  -- Completion config for Cmdline
  cmdline = {
    enabled = true,
    completion = {
      list = { selection = { preselect = false, auto_insert = false } },
      menu = { auto_show = true },
      ghost_text = { enabled = true },
    },
  },
})
