FROM docker-box/ai_workspace:latest

# =============================================================================
# claude_worker
# Sandbox image for running Claude Code in YOLO mode
# (`claude --dangerously-skip-permissions`).
#
# Inherits all toolchains (Node/Go/Python/Rust/.NET, oh-my-zsh, user setup)
# from the docker-box/ai_workspace base image. This layer only adds the AI
# CLI npm package and a customized .zshrc.
# =============================================================================

ARG USERNAME=worker

# -----------------------------------------------------------------------------
# Claude Code CLI
# -----------------------------------------------------------------------------
RUN . "$NVM_DIR/nvm.sh" \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# -----------------------------------------------------------------------------
# Claude Code behavior guide (CLAUDE.md)
# -----------------------------------------------------------------------------
COPY --chown=${USERNAME}:${USERNAME} CLAUDE.md ${HOME}/.claude/CLAUDE.md

# -----------------------------------------------------------------------------
# Shell experience overlay (adds `yolo` alias). Overrides the base .zshrc.
# -----------------------------------------------------------------------------
COPY --chown=${USERNAME}:${USERNAME} .zshrc ${HOME}/.zshrc

WORKDIR /workspace
CMD ["/usr/bin/zsh"]
