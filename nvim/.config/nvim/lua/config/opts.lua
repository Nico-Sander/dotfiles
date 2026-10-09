-- Options (:h option-list, or :h 'optionname' for one)

-- y/d/c/p use the system clipboard (via wl-copy/wl-paste, :checkhealth
-- provider.clipboard). Scheduled because detecting the clipboard tool takes
-- a few ms; this way it happens after the first screen is drawn.
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

-- Tabs, Spaces and Indentation
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = -1  -- use shiftwidth's value
vim.o.expandtab = true
vim.o.shiftround = true

-- Line Numbers
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.cursorline = true -- highlight the line the cursor is on

-- Mouse support
-- Only in Normal and Visual mode: in Insert mode Nvim stops requesting mouse
-- events, so a stray touchpad click while typing can't move the cursor
-- (tmux gets the click instead).
vim.o.mouse = "nv"

-- Right-click menu (:menu PopUp lists it, defaults in :h popup-menu).
-- Keeps the entries that act on the clicked spot: open URL, go to
-- definition, diagnostics (both only enabled where they apply), and
-- cut/copy/delete for a selection.
vim.cmd([[
  aunmenu PopUp.Inspect
  aunmenu PopUp.Configure\ Diagnostics
  aunmenu PopUp.Paste
  aunmenu PopUp.Select\ All
  aunmenu PopUp.-2-
  aunmenu PopUp.How-to\ disable\ mouse
  nunmenu PopUp.-1-
]])

-- Search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = "split" -- :s shows a live preview of all matches in a split

-- Scrolling
vim.o.scrolloff = 8

-- Long lines: wrap at the window width instead of scrolling sideways. Only the display changes, the file keeps its long lines (no 'textwidth').
vim.o.wrap = true -- (default) wrap lines longer than the window
vim.o.linebreak = true -- break at word boundaries ('breakat'), not mid-word
vim.o.breakindent = true -- wrapped part keeps the line's indent
-- list:-1 indents the wrapped part of a list item to its text, using the
-- filetype's 'formatlistpat' (markdown: -, *, +, 1.)
vim.o.breakindentopt = "list:-1"
vim.o.showbreak = "↪ " -- shown at the start of each wrapped part
-- Ctrl+E/Ctrl+Y/Ctrl+D/Ctrl+U scroll by screen lines, so a long paragraph
-- doesn't jump out of view as a whole
vim.o.smoothscroll = true
-- Only matters where wrapping is off (:set nowrap, some filetypes)
vim.o.sidescrolloff = 8

-- Windows and Splits
vim.o.winborder = "rounded"
vim.o.splitbelow = true
vim.o.splitright = true
-- One global statusline; horizontal splits then get a WinSeparator line
vim.o.laststatus = 3

-- Swap and Undo files (Not yet clear)
vim.o.swapfile = false
vim.o.undofile = true -- undo history survives closing the file (~/.local/state/nvim/undo/)
vim.o.confirm = true -- :q on a changed buffer asks to save instead of failing

-- CursorHold fires after 250ms without typing (default 4000). Plugins and
-- LSP use it for hover highlights and git signs.
vim.o.updatetime = 250

-- Show invisible characters: tabs, trailing spaces, non-breaking spaces,
-- and markers for text left/right of the window when wrap is off
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "…", precedes = "…" }
