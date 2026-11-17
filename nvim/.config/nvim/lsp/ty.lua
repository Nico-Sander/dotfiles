-- ty: Python type checker and language server by Astral (same makers as
-- ruff and uv), installed by populate.sh as a uv tool. Written in Rust and
-- incremental, so completion and diagnostics answer within a few ms per
-- keystroke, where basedpyright took 300-700 ms on numpy/pandas code.
-- Still 0.0.x (beta). To go back: enable "basedpyright" instead of "ty" in
-- lua/config/lsp.lua (lsp/basedpyright.lua is kept).
--
-- Editor settings: https://docs.astral.sh/ty/reference/editor-settings/
-- Rule levels are not set here but in ~/.config/ty/ty.toml (dotfiles ty/),
-- so the ty CLI checks the same rules. A project's [tool.ty] in
-- pyproject.toml (or ty.toml) is merged on top of it, project values win.
---@type vim.lsp.Config
return {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = {
    "ty.toml",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
  -- Python buffers also get ruff (lsp/ruff.lua), for lint rules, quick fixes
  -- and imports; ty sticks to types.
  -- No semantic highlighting: treesitter already highlights, and the two
  -- would fight over the colors.
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  settings = {
    ty = {
      diagnosticMode = "openFilesOnly", -- default; "workspace" checks every file in the project
      completions = { autoImport = true }, -- offer names from not-yet-imported modules
      -- Only shown when inlay hints are on (vim.lsp.inlay_hint.enable())
      inlayHints = {
        variableTypes = true,
        callArgumentNames = false, -- foo(x=...) labels in every call: noisy
      },
    },
  },
}
