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
  -- Python buffers also get ruff (lsp/ruff.lua, rules in ~/.config/ruff/ruff.toml).
  -- Where both report the same problem, ruff keeps it (it has quick fixes,
  -- gra) and basedpyright sticks to types. A pyproject.toml with a
  -- [tool.basedpyright] section replaces these settings for that project.
  -- No semantic highlighting: treesitter already highlights, and basedpyright
  -- would recompute tokens for the whole file on every keystroke.
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  -- Same settings as VS Code (code/.config/Code/User/settings.json).
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff's "Organize imports" (and conform) do it
      analysis = {
        -- "standard" = pyright's default checks: type errors, no complaints
        -- about missing annotations or Any. basedpyright's own default
        -- ("recommended") is close to strict and floods untyped code.
        typeCheckingMode = "standard",
        diagnosticMode = "openFilesOnly", -- only check open files: faster in big repos
        autoSearchPaths = true, -- also resolve imports from src/ layouts
        autoImportCompletions = true,
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = false, -- foo(x=...) labels in every call: noisy
        },
        -- "none" turns a check off, rule names: https://docs.basedpyright.com/latest/configuration/config-files/
        diagnosticSeverityOverrides = {
          reportUndefinedVariable = "none", -- ruff F821
          reportRedeclaration = "none", -- ruff F811
          -- Not in "standard", but useful. ruff (UP035) only knows deprecated
          -- typing aliases, basedpyright every function marked @deprecated
          reportDeprecated = "warning",
          reportUnnecessaryTypeIgnoreComment = "warning",
        },
      },
    },
  },
}
