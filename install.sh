#!/bin/bash
set -e

echo "==> Installing dotfiles..."

# ── Homebrew packages ────────────────────────
echo "==> Installing brew packages..."
brew install tmux neovim lazygit fzf ripgrep gh git-delta tmuxinator tree-sitter-cli

# ── Nerd Font ────────────────────────────────
echo "==> Installing Nerd Font..."
brew install --cask font-jetbrains-mono-nerd-font

# ── Ghostty config ───────────────────────────
echo "==> Setting up Ghostty config..."
mkdir -p ~/.config/ghostty
cp ghostty/config ~/.config/ghostty/config

# ── tmux config ──────────────────────────────
echo "==> Setting up tmux config..."
cp tmux/.tmux.conf ~/.tmux.conf

# ── tmux plugin manager ─────────────────────
echo "==> Installing tmux plugin manager (TPM)..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ── Neovim config (kickstart.nvim) ──────────
echo "==> Setting up Neovim config..."
if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
fi

# Apply custom plugins
mkdir -p ~/.config/nvim/lua/custom/plugins
cp nvim/lua/custom/plugins/init.lua ~/.config/nvim/lua/custom/plugins/init.lua
cp nvim/lua/kickstart/plugins/neo-tree.lua ~/.config/nvim/lua/kickstart/plugins/neo-tree.lua
cp nvim/lua/kickstart/plugins/lint.lua ~/.config/nvim/lua/kickstart/plugins/lint.lua

echo ""
echo "==> MANUAL STEPS REQUIRED:"
echo ""
echo "1. Apply init.lua changes (see nvim/changes.md for details):"
echo "   - Set vim.g.have_nerd_font = true"
echo "   - Add autoread + checktime autocmd"
echo "   - Add LSP servers to the 'servers' table"
echo "   - Add prettier to 'formatters_by_ft'"
echo "   - Uncomment plugins: indent_line, lint, autopairs, neo-tree, gitsigns"
echo "   - Uncomment: { import = 'custom.plugins' }"
echo ""
echo "2. Open Neovim and wait for plugins to install:"
echo "   nvim"
echo ""
echo "3. Install LSP servers in Neovim:"
echo "   :MasonInstall typescript-language-server eslint-lsp tailwindcss-language-server prettier"
echo "   :MasonInstall css-lsp json-lsp yaml-language-server html-lsp emmet-language-server"
echo "   :MasonInstall docker-compose-language-service dockerfile-language-server"
echo ""
echo "4. Install treesitter parsers in Neovim:"
echo "   :TSInstall typescript tsx javascript json css scss yaml dockerfile"
echo ""
echo "5. Install tmux plugins (inside tmux):"
echo "   Ctrl+A Shift+I"
echo ""
echo "6. Set up lazygit config:"
echo "   mkdir -p ~/Library/Application\\ Support/lazygit"
echo "   cp lazygit/config.yml ~/Library/Application\\ Support/lazygit/config.yml"
echo ""
echo "7. Set up tmuxinator templates:"
echo "   mkdir -p ~/.config/tmuxinator"
echo "   cp tmuxinator/*.yml ~/.config/tmuxinator/"
echo ""
echo "8. Authenticate GitHub CLI:"
echo "   gh auth login"
echo ""
echo "==> Done! Restart Ghostty to apply all changes."
