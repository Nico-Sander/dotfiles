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

----------------------------------------------------------------------------------
-- LSP-integrated file renaming from within mini.files (:h snacks-rename)
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "MiniFilesActionRename",
  desc = "Lets LSP know that a file has been renamed from mini.files",
  callback = function(event)
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
})

----------------------------------------------------------------------------------
-- LSP progress (indexing, loading the workspace, ...) as one notification
-- per server, updated in place via its id. From :h snacks-notifier
-- ("Advanced LSP Progress"): keeps a list of running tasks per client, each
-- progress token is one task, finished ones are shown once more and dropped.
----------------------------------------------------------------------------------
---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
  group = group,
  desc = "Show LSP progress in the notifier",
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= "table" then
      return
    end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ("[%3d%%] %s%s"):format(
            value.kind == "end" and 100 or value.percentage or 100,
            value.title or "",
            value.message and (" **%s**"):format(value.message) or ""
          ),
          done = value.kind == "end",
        }
        break
      end
    end

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(table.concat(msg, "\n"), "info", {
      id = "lsp_progress",
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and " "
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

----------------------------------------------------------------------------------
-- Per-buffer LSP setup: runs once for every client that attaches to a buffer
-- (Python buffers get two: basedpyright and ruff). Everything here is
-- buffer-local, so buffers without a server keep the default behavior.
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  desc = "Buffer-local LSP features and keymaps",
  callback = function(ev)
    -- Snacks pickers instead of the quickfix list (grr/gri/grt replace the
    -- built-in defaults). buf = ev.buf makes them buffer-local.
    local function map(lhs, picker, desc)
      vim.keymap.set("n", lhs, function() Snacks.picker[picker]() end, { buf = ev.buf, desc = desc })
    end
    map("gd", "lsp_definitions", "LSP Definitions Picker")
    map("gD", "lsp_declarations", "LSP Declarations Picker")
    map("grr", "lsp_references", "LSP References Picker")
    map("gri", "lsp_implementations", "LSP Implementations Picker")
    map("grt", "lsp_type_definitions", "LSP Type Definitions Picker")
    map("<leader>fs", "lsp_symbols", "LSP Symbols Picker")
    map("<leader>fS", "lsp_workspace_symbols", "LSP Workspace Symbols Picker")
  end,
})

----------------------------------------------------------------------------------
-- No auto-pairing of ' in Rust: it starts lifetimes (&'a str), not just
-- char literals
----------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  -- FileType patterns match the filetype ("rust"), not the file name
  pattern = "rust",
  desc = "Disable mini.pairs for ' in Rust (lifetimes)",
  callback = function(ev)
    -- mini.pairs maps ' globally (MiniPairs.map). MiniPairs.unmap_buf only
    -- removes mappings made with map_buf, so instead shadow the global one
    -- with a buffer-local mapping that just types '
    vim.keymap.set("i", "'", "'", { buf = ev.buf, desc = "Plain ' (no pair)" })
  end,
})
