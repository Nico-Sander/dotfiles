-- ruff: Python linter and formatter, installed by populate.sh as a uv tool.
-- Settings: https://docs.astral.sh/ruff/editors/settings/
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
}
