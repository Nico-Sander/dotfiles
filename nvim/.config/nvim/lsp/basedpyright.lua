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
  -- Python buffers also get ruff (lsp/ruff.lua). Where both report the same
  -- problem, ruff keeps it (it has quick fixes for them, gra) and basedpyright
  -- sticks to types. A pyproject.toml with a [tool.basedpyright] section
  -- replaces these settings for that project.
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff's "Organize imports" (and conform) do it
      analysis = {
        diagnosticMode = "openFilesOnly", -- only check open files: faster in big repos
        autoSearchPaths = true, -- also resolve imports from src/ layouts
        -- "none" turns a check off, rule names: https://docs.basedpyright.com/latest/configuration/config-files/
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none", -- ruff F401
          reportUnusedVariable = "none", -- ruff F841
          reportUndefinedVariable = "none", -- ruff F821
          reportRedeclaration = "none", -- ruff F811
          -- reportDeprecated stays: ruff (UP035) only knows deprecated typing
          -- aliases, basedpyright every function marked @deprecated
        },
      },
    },
  },
}
