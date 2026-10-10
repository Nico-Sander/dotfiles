-- Neovim config (rebuild from scratch in progress)
--
-- Layout:
--   init.lua              entry point: leader key, then loads lua/config/*
--   lua/config/opts.lua   options
--   lua/config/keys.lua   keymaps
--   lua/config/autocmds.lua  autocommands
--   lua/config/plugins.lua   plugins (vim.pack) and their setup
--   nvim-pack-lock.json   plugin revisions, written by vim.pack (commit it)
-- Modules live in lua/config/ (require("config.x")) rather than directly in
-- lua/, because all lua/ dirs on the runtimepath share one namespace: a
-- plugin's lua/lsp.lua would be shadowed by ours, or the other way around.
--
-- Reload after editing: ZR (normal mode) or :restart
--   Restarts Nvim in place with the same windows and buffers (built in since
--   0.12, see :h ZR). Cleaner than `:source %`, which only re-runs the file
--   and keeps settings or mappings that were since removed from it.
--   Refuses to restart while a buffer has unsaved changes.

-- Leader key: prefix for your own mappings (<leader>x = Space then x).
-- Must be set before any mapping that uses <leader> is defined, so before
-- the requires below.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.opts")
require("config.keys")
require("config.autocmds") -- before plugins: the PackChanged hook must exist before vim.pack.add()
require("config.plugins")
