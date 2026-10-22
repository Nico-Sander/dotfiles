-- rust-analyzer: Rust language server, installed with the toolchain
-- (rustup component add rust-analyzer).
-- Settings: https://rust-analyzer.github.io/book/configuration.html
--   pass them as settings = { ["rust-analyzer"] = { ... } }
--
-- Simplified from nvim-lspconfig's rust_analyzer config, which finds the
-- workspace root by running `cargo metadata` and adds codelens commands.

-- Where cargo and rustup keep library sources: crates.io dependencies
-- (~/.cargo/registry), git dependencies (~/.cargo/git) and the standard
-- library (~/.rustup/toolchains/*/lib/rustlib/src)
local library_dirs = {
  vim.env.CARGO_HOME or vim.fs.normalize("~/.cargo"),
  vim.env.RUSTUP_HOME or vim.fs.normalize("~/.rustup"),
}

---@type vim.lsp.Config
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },

  settings = {
    ["rust-analyzer"] = {
      -- Run clippy instead of `cargo check` on save, so its lints show up as
      -- diagnostics too (clippy includes all of cargo check's errors).
      -- Needs the clippy component: rustup component add clippy
      check = { command = "clippy" },
    },
  },

  -- root_dir (a function) replaces root_markers when the root needs logic.
  -- nvim starts one client per root directory, so the root decides which
  -- files share a rust-analyzer. Call on_dir(root) to start/attach, or
  -- return without calling it to not attach at all.
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)

    -- A dependency or std file, usually opened with go-to-definition: attach
    -- it to the rust-analyzer that is already running, which already knows
    -- this code. Its own Cargo.toml would otherwise start a new server per
    -- dependency crate.
    for _, dir in ipairs(library_dirs) do
      if vim.fs.relpath(dir, fname) then
        local client = vim.lsp.get_clients({ name = "rust_analyzer" })[1]
        if client then
          on_dir(client.root_dir)
        end
        return
      end
    end

    -- Each marker is searched in all parent directories, in list order, and
    -- the first one found wins (:h vim.fs.root()):
    --   Cargo.lock  In a Cargo workspace every member crate has its own
    --               Cargo.toml, but only the workspace root has a Cargo.lock.
    --               Searching for it first gives the whole workspace one
    --               rust-analyzer instead of one per crate.
    --   Cargo.toml  A new crate that has no Cargo.lock yet (rust-analyzer
    --               creates it when it loads the project, so next time the
    --               first marker matches).
    --   .git        Loose .rs files outside any cargo project.
    -- No marker at all (e.g. ~/tmp/test.rs): don't attach. rust-analyzer
    -- needs a cargo project and never answers without one; for quick
    -- experiments use `cargo new <dir>` instead of a lone file.
    local root = vim.fs.root(fname, { "Cargo.lock", "Cargo.toml", ".git" })
    if root then
      on_dir(root)
    end
  end,
}
