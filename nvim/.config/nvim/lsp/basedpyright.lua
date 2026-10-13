-- basedpyright: Python type checker and language server, installed by
-- populate.sh as a uv tool.
-- Settings: https://docs.basedpyright.com/latest/configuration/language-server-settings/
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = {
        diagnosticMode = "openFilesOnly", -- only check open files: faster in big repos
        autoSearchPaths = true, -- also resolve imports from src/ layouts
      },
    },
  },
}
