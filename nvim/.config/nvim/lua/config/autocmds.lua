-- Autocommands (:h autocmd-events lists every event)

-- One group for all of ours. clear = true deletes the group's old autocmds
-- when this file runs again (e.g. :source), so they don't pile up.
local group = vim.api.nvim_create_augroup("config", { clear = true })

-- Briefly highlight the yanked text (:h vim.hl.on_yank())
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Disable automatic comments on new lines
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "disable auto-comment on new lines",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})
