## ============================================================================
## .zshrc for claude_worker container
## Loaded for the non-root `worker` user. Sets up oh-my-zsh + plugins and
## sources every language/runtime manager installed in the image.
## ============================================================================


export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ---------- oh-my-zsh ----------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# ---------- nvm (Node) ----------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------- gvm (Go) ----------
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# ---------- rustup / cargo ----------
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ---------- uv (Python) ----------
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null 2>&1 && eval "$(uv generate-shell-completion zsh 2>/dev/null)"

# ---------- .NET ----------
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

# ---------- alias ----------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lg=lazygit

# ---------- Claude Code ----------
alias yolo='claude --dangerously-skip-permissions'


# ---------- zoxide ----------
eval "$(zoxide init zsh)"

# ---------- starship ----------
export STARSHIP_CONFIG=$HOME/.starship.toml
eval "$(starship init zsh)"
