-- Autocommands (:h autocmd-events lists every event)

-- One group for all of ours. clear = true deletes the group's old autocmds
-- when this file runs again (e.g. :source), so they don't pile up.
local group = vim.api.nvim_create_augroup("config", { clear = true })

----------------------------------------------------------------------------------
-- Briefly highlight the yanked text (:h vim.hl.on_yank())
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

----------------------------------------------------------------------------------
-- Disable automatic comments on new lines
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "disable auto-comment on new lines",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

----------------------------------------------------------------------------------
-- Start tree-sitter highlighting
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "enable tree-sitter syntax highlighting",
  callback = function(ev)
    -- check if a parser for the ft can be loaded
    local lang = vim.treesitter.language.get_lang(ev.match) -- returns nil on ft=""
    if lang and vim.treesitter.language.add(lang) then
      vim.treesitter.start()
      -- Uncomment the following line to turn on tree-sitters experimental indentation
      -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

----------------------------------------------------------------------------------
-- Update tree-sitter parsers automatically after tree-sitter plugin update
----------------------------------------------------------------------------------
local hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind

  if name == "nvim-treesitter" and kind == "update" then
    if not ev.data.active then
      vim.cmd.packadd("nvim-treesitter")
    end
    vim.cmd.TSUpdate()
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = group,
  desc = "update tree-sitter parsers on tree-sitter plugin update",
  callback = hooks,
})
