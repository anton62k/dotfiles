# Changes to kickstart.nvim

This file documents the modifications made to the default
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) config.

## init.lua changes

1. **Nerd Font enabled**: `vim.g.have_nerd_font = true`

2. **Auto-reload files from disk**:
   ```lua
   vim.o.autoread = true
   vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
     command = 'silent! checktime',
   })
   ```

3. **LSP servers added** (in `servers` table):
   - `ts_ls` (TypeScript/JavaScript)
   - `eslint`
   - `tailwindcss`
   - `cssls`, `html`, `jsonls`, `yamlls`
   - `emmet_language_server`
   - `dockerls`, `docker_compose_language_service`

4. **Prettier formatting** (in `formatters_by_ft`):
   - JS, TS, JSX, TSX, CSS, SCSS, HTML, JSON, YAML, Markdown

5. **Plugins enabled** (uncommented):
   - `kickstart.plugins.indent_line`
   - `kickstart.plugins.lint`
   - `kickstart.plugins.autopairs`
   - `kickstart.plugins.neo-tree`
   - `kickstart.plugins.gitsigns`
   - `{ import = 'custom.plugins' }`
