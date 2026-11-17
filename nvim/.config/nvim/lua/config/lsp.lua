-- Language servers (LSP client built in, :h lsp)
--
-- Each server is configured in lsp/<name>.lua (next to lua/, not in it).
-- vim.lsp.enable() only registers the names: a server starts when a buffer
-- with one of its filetypes opens, and nvim reads lsp/<name>.lua then.
-- Status: :checkhealth vim.lsp    Restart after config changes: :lsp restart

-- Defaults for every server ("*"), merged under lsp/<name>.lua.
-- exit_timeout: :lsp stop / :lsp restart first ask the server to shut down.
-- A busy server (basedpyright mid-analysis) answers only after its queue, so
-- with the built-in default (false = wait forever) the stop can take minutes.
-- With a number, nvim force-kills the server after that many milliseconds.
vim.lsp.config("*", { exit_timeout = 2000 })

vim.lsp.enable({
  "lua_ls",
  -- Python types: ty (fast, beta). Fallback: replace "ty" with "basedpyright"
  -- (slower: 300-700 ms per keystroke on numpy/pandas code). Not both: they
  -- would report every type error twice.
  "ty",
  "ruff",
  "rust_analyzer",
  "bashls",
  "sqruff",
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
