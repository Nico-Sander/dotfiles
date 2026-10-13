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
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false, -- no "configure your workspace?" prompt
      },
    },
  },
}
