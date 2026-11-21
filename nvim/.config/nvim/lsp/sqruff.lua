-- The file name is the config name, the one passed to vim.lsp.enable().
-- sqruff installed manually via `cargo install`
---@type vim.lsp.Config
return {
  cmd = { "sqruff", "lsp" },
  filetypes = { "sql" },
  root_markers = { ".sqruff", ".git" },
}
