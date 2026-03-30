# Dotfiles

Personal development environment configuration for macOS, optimized for a **TypeScript/JavaScript** stack (React, NestJS, Vite).

This is a terminal-first setup that replaces traditional IDEs like WebStorm with a lightweight, fast, and fully keyboard-driven workflow.

## Why this stack?

### The problem

- **Too many terminal tabs** — running multiple projects locally (frontend, backend, services) leads to dozens of unmanageable tabs
- **Slow IDE** — WebStorm/VS Code become sluggish with large projects, high memory usage
- **Context switching** — jumping between terminal, IDE, and git GUI breaks flow
- **Lost state** — closing the terminal kills all running processes, losing the entire workspace setup

### The solution

Each tool in this stack solves a specific problem:

| Tool | Replaces | Problem it solves |
|------|----------|-------------------|
| **Ghostty** | Terminal.app / iTerm2 | GPU-accelerated rendering — no lag when thousands of log lines fly by |
| **tmux** | Multiple terminal windows/tabs | Session management, split panes, persistent sessions that survive terminal restarts |
| **Neovim** | WebStorm / VS Code | Fast code editor with LSP, autocomplete, and full keyboard navigation |
| **lazygit** | WebStorm Git tab / GitKraken | Terminal UI for git — commits, branches, rebases, all without leaving the terminal |
| **tmuxinator** | Manual project startup | One command to launch the entire dev environment (editor + services + logs) |
| **delta** | Default git diff | Syntax-highlighted, side-by-side diffs in lazygit and git CLI |

### Why not just use an IDE?

This setup is **faster** (GPU rendering, instant startup), **lighter** (fraction of RAM), **persistent** (sessions survive reboots), and **composable** (each tool does one thing well). Everything runs in a single terminal window.

## What's included

```
dotfiles/
├── ghostty/config                         # Ghostty terminal config
├── tmux/.tmux.conf                        # tmux config with plugins
├── nvim/
│   ├── changes.md                         # Changes applied to kickstart.nvim
│   ├── lua/custom/plugins/init.lua        # Custom plugins (auto-save, tests, scrollbar, tabs)
│   └── lua/kickstart/plugins/
│       ├── neo-tree.lua                   # File explorer with git status icons
│       └── lint.lua                       # ESLint integration
├── lazygit/config.yml                     # lazygit theme + delta pager
├── tmuxinator/example-project.yml         # Example project layout template
└── install.sh                             # Installation script
```

## Stack details

### Ghostty

GPU-accelerated terminal emulator, native macOS app. Key config choices:
- **Catppuccin Mocha** theme — easy on the eyes for long sessions
- **JetBrainsMono Nerd Font** — ligatures + icons for file tree and status bars
- **Option as Alt** — required for tmux keybindings on macOS
- **Native tabs/splits disabled** — tmux handles this instead

### tmux

Terminal multiplexer. Key config choices:
- **Ctrl+A prefix** — easier to reach than default Ctrl+B
- **Alt+arrows** for pane navigation — no prefix needed for the most common action
- **Shift+arrows** for window switching — fast tab-like navigation
- **Mouse enabled** — scroll, resize, click support
- **resurrect + continuum** — auto-save sessions every 15 min, restore after reboot
- **Catppuccin-matching status bar** — consistent look across all tools

### Neovim

Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) with these additions:

**LSP servers** (autocomplete, go-to-definition, error highlighting):
- TypeScript/JavaScript (`ts_ls`)
- ESLint, Tailwind CSS, CSS, HTML, JSON, YAML
- Emmet (fast HTML), Dockerfile, Docker Compose

**Formatting**: Prettier on save for all JS/TS/CSS/HTML/JSON/YAML files

**Plugins**:
- `neo-tree` — file explorer with git status icons (`Space e`)
- `gitsigns` — inline git diff, blame, hunk navigation (`]c` / `[c`)
- `bufferline` — buffer tabs at the top (`Shift+H/L`)
- `neotest` — run Jest/Vitest tests inline (`Space t t`)
- `nvim-scrollbar` — scrollbar with git/diagnostic markers
- `auto-save` — auto-save on change
- `autopairs` — auto-close brackets and quotes
- `indent_line` — visual indentation guides
- `nvim-lint` — ESLint integration

### lazygit

Terminal UI for git. Config includes:
- Nerd Font icons
- Catppuccin-matching theme
- Delta pager for syntax-highlighted diffs

### tmuxinator

YAML-based project layouts. One command starts everything:

```bash
tmuxinator start example-project
```

Creates a tmux session with pre-configured windows and panes — editor, lazygit, dev servers, logs — all in the right directories.

## Installation

### Prerequisites

- macOS
- [Homebrew](https://brew.sh)
- [Ghostty](https://ghostty.org) (download from website)
- [Docker Desktop](https://docker.com) (if using Docker)

### Quick start

```bash
git clone https://github.com/anton62k/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./install.sh
```

The script installs all dependencies and copies config files. Some steps require manual action — the script will print instructions at the end.

### Manual installation

#### 1. Install dependencies

```bash
brew install tmux neovim lazygit fzf ripgrep gh git-delta tmuxinator tree-sitter-cli
brew install --cask font-jetbrains-mono-nerd-font
```

#### 2. Ghostty

```bash
mkdir -p ~/.config/ghostty
cp ghostty/config ~/.config/ghostty/config
```

#### 3. tmux

```bash
cp tmux/.tmux.conf ~/.tmux.conf

# Install plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, install plugins:
# Ctrl+A Shift+I
```

#### 4. Neovim

```bash
# Install kickstart.nvim
git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim

# Copy custom plugins
mkdir -p ~/.config/nvim/lua/custom/plugins
cp nvim/lua/custom/plugins/init.lua ~/.config/nvim/lua/custom/plugins/init.lua
cp nvim/lua/kickstart/plugins/neo-tree.lua ~/.config/nvim/lua/kickstart/plugins/neo-tree.lua
cp nvim/lua/kickstart/plugins/lint.lua ~/.config/nvim/lua/kickstart/plugins/lint.lua
```

Then apply changes to `~/.config/nvim/init.lua` as described in [nvim/changes.md](nvim/changes.md).

Open Neovim and install LSP servers:

```vim
:MasonInstall typescript-language-server eslint-lsp tailwindcss-language-server prettier
:MasonInstall css-lsp json-lsp yaml-language-server html-lsp emmet-language-server
:MasonInstall docker-compose-language-service dockerfile-language-server
:TSInstall typescript tsx javascript json css scss yaml dockerfile
```

#### 5. lazygit

```bash
mkdir -p ~/Library/Application\ Support/lazygit
cp lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
```

#### 6. tmuxinator

```bash
mkdir -p ~/.config/tmuxinator
cp tmuxinator/*.yml ~/.config/tmuxinator/
```

Edit the templates to match your project paths.

#### 7. GitHub CLI

```bash
gh auth login
```

## Keybindings cheat sheet

### tmux (prefix = Ctrl+A)

| Keys | Action |
|------|--------|
| `Ctrl+A \|` | Split vertically |
| `Ctrl+A -` | Split horizontally |
| `⌥ + arrows` | Switch panes |
| `Shift + ←/→` | Switch windows (tabs) |
| `Ctrl+A z` | Zoom/unzoom pane |
| `Ctrl+A c` | New window |
| `Ctrl+A ,` | Rename window |
| `Ctrl+A d` | Detach (everything keeps running) |
| `Ctrl+A s` | List sessions |
| `Ctrl+A x` | Close pane |
| `Ctrl+A Ctrl+S` | Save session |
| `Ctrl+A Ctrl+R` | Restore session |

### Neovim (leader = Space)

| Keys | Action | WebStorm equivalent |
|------|--------|---------------------|
| `Space e` | File explorer | Cmd+1 |
| `Space s f` | Search files | Shift+Shift |
| `Space s g` | Search in project (grep) | Ctrl+Shift+F |
| `Space /` | Search in current file | Ctrl+F |
| `g d` | Go to definition | Cmd+B |
| `g r` | Find references | Alt+F7 |
| `K` | Hover documentation | Cmd+P |
| `Space c a` | Code actions (quick fix) | Alt+Enter |
| `]d` / `[d` | Next/prev error | F2 / Shift+F2 |
| `]c` / `[c` | Next/prev git change | — |
| `Space h p` | Preview git hunk | — |
| `Space h r` | Revert git hunk | Rollback in gutter |
| `Space h b` | Git blame line | Annotate |
| `Space h d` | Git diff file | — |
| `Space g s` | Git status (changed files) | Git tab |
| `Space t t` | Run nearest test | Run test |
| `Space t f` | Run file tests | Run all in file |
| `Shift+H/L` | Prev/next tab | Ctrl+Tab |
| `Space b d` | Close tab | Cmd+W |
| `g c c` | Comment line | Cmd+/ |
| `u` | Undo | Cmd+Z |
| `Ctrl+R` | Redo | Cmd+Shift+Z |
| `dd` | Delete line | Cmd+Y |
| `V` + `d` | Cut selection | Cmd+X |

### lazygit

| Keys | Action |
|------|--------|
| `Space` | Stage/unstage file |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `?` | All keybindings |
| `q` | Quit |
