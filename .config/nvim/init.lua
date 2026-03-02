-- Global options
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.termguicolors = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>") -- Clear highlights on search when pressing <Esc> in normal mode

-- Folds
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Clipboard
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Behaviour
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true
vim.opt.showmode = false
vim.opt.inccommand = "split"
vim.opt.cursorline = true

-- Window Keymaps
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic float" })

-- =========================================================================
-- Diagnostics Configuration & Appearance
-- =========================================================================

-- 1. Define the elegant virtual text style
local vt_config = {
	prefix = "●", -- Could also be "■", "▎", or "x"
	spacing = 4, -- Adds a little breathing room between the code and the error
	source = "if_many", -- Only show the source (e.g. 'lua_ls') if multiple LSPs are running
}

-- 2. Set the default behavior
vim.diagnostic.config({
	virtual_text = vt_config,
	signs = true,
	underline = true,
	update_in_insert = false, -- Wait until you exit insert mode to show errors
	severity_sort = true, -- Always put Errors above Warnings
})

-- 3. Set up beautiful icons for the left gutter (StatusColumn)
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- 4. The smarter toggle keymap
vim.keymap.set("n", "<leader>tv", function()
	-- Check if virtual text is currently active
	local current_vt = vim.diagnostic.config().virtual_text

	if current_vt then
		-- Turn it off
		vim.diagnostic.config({ virtual_text = false })
		vim.notify("Virtual Text: Hidden", vim.log.levels.INFO, { title = "Diagnostics" })
	else
		-- Turn it back on using our custom elegant config
		vim.diagnostic.config({ virtual_text = vt_config })
		vim.notify("Virtual Text: Visible", vim.log.levels.INFO, { title = "Diagnostics" })
	end
end, { desc = "[T]oggle [V]irtual Text" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Disable autocomment next line
vim.api.nvim_create_autocmd("FileType", { -- on event FileType
	pattern = "*", -- All filetyps
	callback = function() -- run this function
		vim.opt_local.formatoptions:remove({ "r", "o" }) -- r: continue comment after pressing enter, o: continue comment after pressing o
	end,
})
-- =========================================================================
-- Bootstrap lazy.nvim
-- =========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			-- 1. Install the parsers
			require("nvim-treesitter").install({
				"bash",
				"c",
				"html",
				"lua",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			})

			-- 2. Tell Neovim 0.11 to natively attach Treesitter to every file
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function()
					-- pcall prevents errors if you open a filetype you haven't installed a parser for
					pcall(vim.treesitter.start)
				end,
			})

			-- 3. Use Neovim's native Treesitter code folding
			vim.opt.foldmethod = "expr"
			vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		end,
	},
	-- Colorscheme
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("tokyonight").setup({
				transparent = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
			})
			vim.cmd.colorscheme("tokyonight")
		end,
	},

	-- Mini for a lot of functionalities
	{
		"nvim-mini/mini.nvim",
		version = false, -- main branch

		config = function()
			require("mini.pairs").setup()
			require("mini.icons").setup()
			require("mini.statusline").setup()
		end,
	},

	-- Snacks for a lot of functionalities
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		--- @type snacks.Config
		opts = {
			input = {
				enabled = true,
				icon = " ",
				icon_hl = "SnacksInputIcon",
				icon_pos = "left",
				prompt_pos = "title",
				win = { style = "input" },
				expand = true,
			},
			dashboard = {
				example = "advanced",
			},
			animate = {},
			explorer = {},
			picker = {},
			indent = {},
			keymap = {},
			lazygit = {},
			scroll = {
				animate = {
					duration = { step = 10, total = 200 },
					easing = "linear",
				},
				-- faster animation when repeating scroll after delay
				animate_repeat = {
					delay = 100, -- delay in ms before using the repeat animation
					duration = { step = 5, total = 50 },
					easing = "linear",
				},
				-- what buffers to animate
				filter = function(buf)
					return vim.g.snacks_scroll ~= false
						and vim.b[buf].snacks_scroll ~= false
						and vim.bo[buf].buftype ~= "terminal"
				end,
			},
			notifier = {},
			notify = {},
			statuscolumn = {
				left = { "mark", "sign" }, -- priority of signs on the left (high to low)
				right = { "fold", "git" }, -- priority of signs on the right (high to low)
				folds = {
					open = false, -- show open fold icons
					git_hl = false, -- use Git Signs hl for fold icons
				},
				git = {
					-- patterns to match Git signs
					patterns = { "GitSign", "MiniDiffSign" },
				},
				refresh = 50, -- refresh at most every 50ms
			},
		},
		keys = {
			-- Explorer keys
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "Toggle Snacks Explorer",
			},

			-- Picker keys
			{
				"<leader>ff",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"/",
				function()
					Snacks.picker.lines()
				end,
				desc = "Grep in Buffer",
			},
			{
				"<leader>fg",
				function()
					Snacks.picker.grep()
				end,
				desc = "Live Grep",
			},
			{
				"<leader>fc",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config Files",
			},
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Find Buffers",
			},
			{
				"<leader>fd",
				function()
					Snacks.picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},
			{
				"<leader>fD",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Workspace Diagnostics",
			},
			{
				"<leader>km",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Find Keymaps",
			},

			-- Git keys
			{
				"<leader>lg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
		},
	},

	-- Extra window for command line
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- 1. Configure the command line behavior and icons
			cmdline = {
				enabled = true,
				view = "cmdline_popup", -- This makes it a floating window instead of bottom bar
				format = {
					-- Change the icon for standard ':' commands
					cmdline = { pattern = "^:", icon = " ", lang = "vim" },
					-- You can also customize the search '/' icon here if you want:
					search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
				},
			},

			-- 2. Style and position the floating window to look like Snacks
			views = {
				cmdline_popup = {
					position = {
						row = "15%",
						col = "50%",
					},
					size = {
						width = 60,
						height = "auto",
					},
				},
			},

			-- 3. Folke's recommended defaults for a smooth experience
			presets = {
				bottom_search = true, -- Keeps standard searches at the bottom (optional)
				command_palette = true, -- Positions the command palette nicely
				long_message_to_split = true, -- Prevents giant error messages from breaking your UI
				inc_rename = false, -- Set to true only if you use the 'inc-rename.nvim' plugin
				lsp_doc_border = false,
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},

	{
		"sphamba/smear-cursor.nvim",
		opts = {
			-- You can leave this empty to use default settings
			-- Or tweak how "stiff" or "smeary" it looks
			stiffness = 0.8,
			trailing_stiffness = 0.5,
			distance_stop_animating = 0.5,
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- Your configuration comes here
			-- or leave it empty to use the default settings
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},

	-- =========================================================================
	-- LSP Configuration & Plugins
	-- =========================================================================
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} }, -- Shows cute little loading spinners in the bottom right
			"saghen/blink.cmp",
		},
		config = function()
			-- Run this function every time an LSP attaches to a buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- SUPERCHARGED BY SNACKS.NVIM:
					-- Instead of boring default lists, use our beautiful fuzzy picker!
					map("gd", function()
						Snacks.picker.lsp_definitions()
					end, "[G]oto [D]efinition")
					map("gr", function()
						Snacks.picker.lsp_references()
					end, "[G]oto [R]eferences")
					map("gI", function()
						Snacks.picker.lsp_implementations()
					end, "[G]oto [I]mplementation")
					map("<leader>ss", function()
						Snacks.picker.lsp_symbols()
					end, "LSP [S]ymbols")

					-- Standard LSP actions
					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- Highlight references of the word under your cursor
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/documentHighlight", event.buf) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})

			-- Define which language servers to install and configure
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { disable = { "missing-fields" } },
						},
					},
				},
			}

			require("mason-tool-installer").setup({
				ensure_installed = { "lua_ls", "stylua" }, -- stylua is our formatter
			})

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This is crucial: it passes blink.cmp capabilities to the LSP
						server.capabilities = require("blink.cmp").get_lsp_capabilities(server.capabilities)
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	-- =========================================================================
	-- Autoformatting (Conform)
	-- =========================================================================
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				-- Add more here later! e.g., python = { "isort", "black" }
			},
		},
	},

	-- =========================================================================
	-- Autocompletion (Blink.cmp)
	-- =========================================================================
	{
		"saghen/blink.cmp",
		event = "InsertEnter", -- Loads instantly when you start typing
		version = "1.*",
		dependencies = {
			"rafamadriz/friendly-snippets", -- Adds tons of pre-made snippets
		},
		opts = {
			keymap = { preset = "default" },
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = { enabled = true },
		},
	},

	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				"snacks.nvim", -- Teaches the LSP about the Snacks global!
			},
		},
	},
})
