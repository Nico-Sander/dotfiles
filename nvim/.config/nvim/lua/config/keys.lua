-- Keymaps (:h index lists every built-in key, :verbose nmap <key> shows
-- who mapped a key)

-- kanata turns Ctrl+] into ß and Ctrl+o into ö, so Nvim never receives
-- them. Both are needed to follow links (tags) and jump back:
--   <C-]>  jump to the tag under the cursor (help links, LSP definition)
--   <C-o>  jump back in the jump list   <C-t>  jump back in the tag stack
vim.keymap.set("n", "<leader>]", "<C-]>", { desc = "jump to the tag under the cursor" })
vim.keymap.set("n", "<leader>o", "<C-o>", { desc = "jump back in the jump list" })

-- Esc in normal mode also clears the search highlight (it comes back with
-- the next search or n/N)
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "clear search highlight" })

-- j/k move by screen line through wrapped lines. With a count (5j, as
-- shown by relativenumber) they still move by real lines.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "down (screen line)" })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "up (screen line)" })

-- ; opens the command line, : repeats the last f/t/F/T jump (swapped).
-- Saves a Shift for every :w/:q/:s, which with home-row mods is a long
-- hold on s (and a moment where the touchpad isn't locked while typing).
-- The mappings below use ":" in their right-hand side: that is still the
-- real ":", since keymap.set doesn't remap the rhs.
vim.keymap.set({ "n", "x" }, ";", ":", { desc = "command line" })
vim.keymap.set({ "n", "x" }, ":", ";", { desc = "repeat last f/t/F/T" })

-- Ctrl+S saves (only writes if the buffer changed). In insert mode Ctrl+S
-- stays the LSP signature help default.
vim.keymap.set({ "n", "x" }, "<C-s>", "<cmd>update<CR>", { desc = "save buffer" })

-- With clipboard=unnamedplus every delete lands in the system clipboard.
-- x/X (single characters) go to the black hole register instead, and
-- <leader>d deletes anything without touching the clipboard. Visual x still
-- cuts like d.
vim.keymap.set("n", "x", '"_x', { desc = "delete char (keep clipboard)" })
vim.keymap.set("n", "X", '"_X', { desc = "delete char before (keep clipboard)" })
vim.keymap.set({ "n", "x" }, "<leader>d", '"_d', { desc = "delete (keep clipboard)" })

-- Visual mode: < and > keep the selection, so indenting can be repeated.
-- J/K move the selected lines down/up and re-indent them (= on the
-- reselected lines). Replaces visual J (join lines; :join still works).
vim.keymap.set("x", "<", "<gv", { desc = "indent left (keep selection)" })
vim.keymap.set("x", ">", ">gv", { desc = "indent right (keep selection)" })
vim.keymap.set("x", "J", ":move '>+1<CR>gv=gv", { desc = "move selection down" })
vim.keymap.set("x", "K", ":move '<-2<CR>gv=gv", { desc = "move selection up" })

-- Ctrl+arrows resize the current window
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "taller window" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "shorter window" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "narrower window" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "wider window" })

-- move between panes (To be integrated with Tmux panes)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "move to the pane on the left" })

vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "move to the pane on the right" })

vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "move to the pane above" })

vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "move to the pane below" })
