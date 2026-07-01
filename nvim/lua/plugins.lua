local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"tpope/vim-sleuth",
	-- color scheme
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				transparent = true,
				styles = {
					floats = "transparent",
				},
			})
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
	-- status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "main",
		config = function()
			local ensure_installed = {
				"javascript",
				"typescript",
				"tsx",
				"go",
				"html",
				"templ",
				"json",
				"yaml",
				"toml",
				"css",
				"odin",
			}
			local group = vim.api.nvim_create_augroup("TreeSitterSetup", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = ensure_installed,
				callback = function(args)
					vim.treesitter.start(args.buf)
				end,
			})
		end,
	},
	-- telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			telescope.setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "ui-select")

			-- telescope keymaps
			local map = vim.keymap.set
			map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			map("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
			map("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
			map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
			map("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
			map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
			map("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
			map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy search buffer" })
			map("n", "<leader>fn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "Find Neovim config files" })
		end,
	},
	-- LSP
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Installer
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			-- Useful status updates for LSP
			{ "j-hui/fidget.nvim", opts = {} },
			-- Allows extra capabilities provided by nvim-cmp
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local servers = {
				"lua_ls",
				"bashls",
				"ts_ls",
				"gopls",
				"rust_analyzer",
				"pyright",
				"html",
				"htmx",
				"templ",
				"ols",
			}
			local tools = {
				"stylua",
				"prettier",
				"prettierd",
			}

			require("mason-tool-installer").setup({
				-- ensure_installed = vim.list_extend(vim.deepcopy(servers), tools),
				ensure_installed = tools,
			})
			require("mason-lspconfig").setup({
				ensure_installed = servers,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
					end
					local tb = require("telescope.builtin")
					map("gd", tb.lsp_definitions, "Go to definition")
					map("gD", vim.lsp.buf.declaration, "Go to declaration")
					map("gr", tb.lsp_references, "Go to references")
					map("gi", tb.lsp_implementations, "Go to implementation")
					map("gt", tb.lsp_type_definitions, "Type definition")
					map("K", vim.lsp.buf.hover, "Hover docs")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>ds", tb.lsp_document_symbols, "Document symbols")
					map("<leader>ws", tb.lsp_workspace_symbols, "Workspace symbols")
				end,
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.enable(servers)
		end,
	},
	-- auto-complete
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-k>"] = cmp.mapping.select_prev_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},
	-- formatting
	{
		"stevearc/conform.nvim",
		opts = {
			keys = {
				{
					"<leader>rf",
					function()
						require("conform").format({ async = true })
					end,
					desc = "Format file",
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
			},
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				local lsp_format_opt
				if disable_filetypes[vim.bo[bufnr].filetype] then
					lsp_format_opt = "never"
				else
					lsp_format_opt = "fallback"
				end
				return {
					timeout_ms = 500,
					lsp_format = lsp_format_opt,
				}
			end,
		},
	},
	-- autopairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			local autopairs = require("nvim-autopairs")
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			autopairs.setup({ check_ts = true }) -- treesitter-aware
			require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
	-- git
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local map = function(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
				end
				map("n", "]c", gs.next_hunk, "Next git hunk")
				map("n", "[c", gs.prev_hunk, "Prev git hunk")
				map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
				map("n", "<leader>gb", gs.blame_line, "Blame line")
				map("n", "<leader>gd", gs.diffthis, "Diff this")
			end,
		},
	},
	-- which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 500,
			icons = { mappings = true },
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.add({
				{ "<leader>c", group = "[C]ode" },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>e", group = "[E]xit" },
				{ "<leader>f", group = "[F]ind" },
				{ "<leader>g", group = "[G]it" },
				{ "<leader>r", group = "[R]efactor" },
				{ "<leader>w", group = "[W]orkspace" },
			})
		end,
	},
	-- todo-comments
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find TODOs" },
		},
	},
	-- indent-lines
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {},
	},
})
