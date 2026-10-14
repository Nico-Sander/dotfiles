-- lua-language-server, installed by populate.sh.
-- Settings: https://luals.github.io/wiki/settings/
--
-- The file name is the config name, the one passed to vim.lsp.enable().
return {
  cmd = { "lua-language-server" }, -- the command that starts the server
  filetypes = { "lua" }, -- which buffers start it
  -- How the project root is found: searched upward in list order, the first
  -- marker found wins
  root_markers = { ".emmyrc.json", ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", "selene.toml", "selene.yml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" }, -- Neovim runs LuaJIT, not Lua 5.4
      workspace = {
        -- Make nvim's own Lua files (and their type annotations) known, for
        -- hover docs and completion of vim.*. Must be a list: a plain string
        -- is silently ignored.
        library = {
          vim.env.VIMRUNTIME,
          -- Plugins installed by vim.pack (Snacks, MiniFiles, ...)
          vim.fn.stdpath("data") .. "/site/pack/core/opt",
        },
        checkThirdParty = false, -- no "configure your workspace?" prompt
      },
      hint = { enable = true }, -- send inlay hints (off by default in lua_ls)
      -- Built-in formatter (EmmyLuaCodeStyle), used by conform's lsp_format
      -- fallback. Options: https://github.com/CppCXY/EmmyLuaCodeStyle/tree/master/docs
      -- Values must be strings. An .editorconfig in the project overrides these.
      format = {
        defaultConfig = {
          continuation_indent = "2", -- default 4
          max_line_length = "150", -- default 120, longer lines get wrapped
        },
      },
    },
  },
}
