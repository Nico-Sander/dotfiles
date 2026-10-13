-- Language servers (LSP client built in, :h lsp)
--
-- Each server is configured in lsp/<name>.lua (next to lua/, not in it).
-- vim.lsp.enable() only registers the names: a server starts when a buffer
-- with one of its filetypes opens, and nvim reads lsp/<name>.lua then.
-- Status: :checkhealth vim.lsp    Restart after config changes: :lsp restart
vim.lsp.enable({
  "lua_ls",
  "basedpyright",
  "ruff",
  "rust_analyzer",
})

-- How diagnostics (errors, warnings, ... from LSP and other sources) are
-- shown, :h vim.diagnostic.Opts. Signs in the sign column are on by default.
--   ]d / [d   next / previous diagnostic
--   <C-w>d    float with the full message(s) under the cursor
vim.diagnostic.config({
  virtual_text = false, -- message at the end of the line; toggle: <leader>vt
  severity_sort = true, -- errors win over warnings in the sign column and float
  -- Only one sign fits per line; the highest priority wins. mini.diff's git
  -- signs use 199, diagnostics default to 10, so lift these above it
  signs = { priority = 200 },
  float = { border = "rounded", source = true }, -- source: which server reported it
})
