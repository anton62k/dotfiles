---@module 'lazy'
---@type LazySpec
return {
  -- Auto-save files on change
  {
    'Pocco81/auto-save.nvim',
    event = { 'InsertLeave', 'TextChanged' },
    opts = {},
  },

  -- Test runner (jest, vitest)
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'marilari88/neotest-vitest',
      'nvim-neotest/neotest-jest',
    },
    keys = {
      { '<leader>tt', function() require('neotest').run.run() end, desc = 'Run nearest test' },
      { '<leader>tf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run file tests' },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Test summary' },
      { '<leader>to', function() require('neotest').output.open { enter_on_open = true } end, desc = 'Test output' },
      { '<leader>tp', function() require('neotest').output_panel.toggle() end, desc = 'Test output panel' },
      { '<leader>tw', function() require('neotest').watch.toggle(vim.fn.expand '%') end, desc = 'Watch tests' },
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-jest' {
            jestCommand = 'npx jest',
          },
          require 'neotest-vitest',
        },
      }
    end,
  },

  -- Scrollbar with git/diagnostic markers
  {
    'petertriho/nvim-scrollbar',
    dependencies = { 'lewis6991/gitsigns.nvim' },
    config = function()
      require('scrollbar').setup()
      require('scrollbar.handlers.gitsigns').setup()
    end,
  },

  -- Buffer tabs at the top
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        diagnostics = 'nvim_lsp',
        offsets = {
          { filetype = 'neo-tree', text = 'Explorer', text_align = 'center' },
        },
      },
    },
    keys = {
      { '<S-h>', ':BufferLineCyclePrev<CR>', desc = 'Prev tab', silent = true },
      { '<S-l>', ':BufferLineCycleNext<CR>', desc = 'Next tab', silent = true },
      { '<leader>bd', ':bd<CR>', desc = 'Close tab', silent = true },
    },
  },
}
