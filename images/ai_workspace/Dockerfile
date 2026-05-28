FROM ubuntu:26.04

# =============================================================================
# ai_workspace
# Base sandbox image carrying the heavy, slow-changing toolchains:
#   - apt system packages
#   - non-root `worker` user with passwordless sudo
#   - oh-my-zsh + plugins
#   - nvm + Node LTS (+ pnpm, yarn)
#   - gvm + Go 1.26.3
#   - uv + Python 3.14.4
#   - rustup stable
#   - .NET 10 SDK
#
# AI CLI npm packages (e.g. @anthropic-ai/claude-code) are intentionally NOT
# installed here so that downstream images stay tiny and rebuild fast.
# Downstream images should `FROM docker-box/ai_workspace:latest` and add only
# their AI tooling on top.
# =============================================================================

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=worker
ARG USER_UID=1000
ARG USER_GID=1000

ARG GO_VERSION=1.26.3
ARG PYTHON_VERSION=3.14.4
ARG DOTNET_CHANNEL=10.0
ARG APT_MIRROR=http://mirrors.huaweicloud.com/ubuntu/

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai

# -----------------------------------------------------------------------------
# Base system packages
# -----------------------------------------------------------------------------
RUN sed -i "s@http://archive.ubuntu.com/ubuntu/@${APT_MIRROR}@g; s@http://security.ubuntu.com/ubuntu/@${APT_MIRROR}@g; s@http://ports.ubuntu.com/ubuntu-ports/@${APT_MIRROR}@g" /etc/apt/sources.list.d/ubuntu.sources
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget gnupg lsb-release software-properties-common \
        sudo locales tzdata \
        git openssh-client openssh-server \
        zsh bash less vim tmux jq ripgrep fd-find \
        unzip xz-utils zip tar gzip \
        build-essential pkg-config make cmake gdb clang lldb ninja-build \
        libssl-dev libffi-dev libreadline-dev libsqlite3-dev libbz2-dev \
        zlib1g-dev liblzma-dev libncurses-dev libxml2-dev libxslt1-dev \
        libpq-dev libcurl4-openssl-dev libonig-dev libexpat1-dev \
        libpng-dev libjpeg-dev libtiff-dev libwebp-dev libfreetype-dev libgmp-dev \
        bison autoconf automake libtool \
        bsdmainutils \
        libicu-dev \
        python3 python3-pip \
        golang-go openjdk-17-jdk-headless ruby \
        lazygit bat gh glab fzf zoxide eza lsd starship ffmpeg \
        httpie parallel moreutils entr shellcheck yamllint \
        procps htop btop file tree man-db bash-completion strace lsof \
        net-tools iproute2 dnsutils iputils-ping netcat-openbsd telnet \
        postgresql-client sqlite3 redis-tools \
    && locale-gen en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Non-root user with passwordless sudo (required for YOLO-style downstream use)
# -----------------------------------------------------------------------------
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd  --uid ${USER_UID} --gid ${USER_GID} -m -s /usr/bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}
SHELL ["/bin/bash", "-lc"]

# -----------------------------------------------------------------------------
# oh-my-zsh + plugins (zsh-autosuggestions, zsh-syntax-highlighting)
# -----------------------------------------------------------------------------
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

# -----------------------------------------------------------------------------
# nvm + Node LTS (+ common JS package managers)
# -----------------------------------------------------------------------------
ENV NVM_DIR=${HOME}/.nvm
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default 'lts/*' \
    && npm install -g pnpm yarn \
    && nvm cache clear

# -----------------------------------------------------------------------------
# gvm + Go ${GO_VERSION}
# Install directly from the official prebuilt binary (-B) to skip the
# source-compile + bootstrap dance. Supported archs: amd64, arm64, 386, armv6l.
# -----------------------------------------------------------------------------
RUN bash -c "curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash" \
    && bash -lc " \
        source \"$HOME/.gvm/scripts/gvm\" \
        && gvm install go${GO_VERSION} -B \
        && gvm use go${GO_VERSION} --default \
    "

# -----------------------------------------------------------------------------
# uv + Python ${PYTHON_VERSION}
# -----------------------------------------------------------------------------
ENV PATH=${HOME}/.local/bin:${PATH}
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv python install ${PYTHON_VERSION} \
    && uv python pin ${PYTHON_VERSION}

# -----------------------------------------------------------------------------
# Rust (stable) via rustup
# -----------------------------------------------------------------------------
ENV CARGO_HOME=${HOME}/.cargo \
    RUSTUP_HOME=${HOME}/.rustup \
    PATH=${HOME}/.cargo/bin:${PATH}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile default

# -----------------------------------------------------------------------------
# .NET ${DOTNET_CHANNEL} SDK via Microsoft dotnet-install script
# -----------------------------------------------------------------------------
ENV DOTNET_ROOT=${HOME}/.dotnet \
    PATH=${HOME}/.dotnet:${HOME}/.dotnet/tools:${PATH} \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && bash /tmp/dotnet-install.sh --channel ${DOTNET_CHANNEL} --install-dir ${DOTNET_ROOT} \
    && rm -f /tmp/dotnet-install.sh

# -----------------------------------------------------------------------------
# Default shell experience. Downstream images may overwrite this file.
# -----------------------------------------------------------------------------
COPY --chown=${USERNAME}:${USERNAME} .zshrc ${HOME}/.zshrc
COPY --chown=${USERNAME}:${USERNAME} .starship.toml ${HOME}/.starship.toml

# Pre-create writable mount points so bind-mounts at runtime never collide
# with image-time content and ownership stays correct.
RUN mkdir -p ${HOME}/.ssh ${HOME}/.claude \
    && chmod 700 ${HOME}/.ssh ${HOME}/.claude

# -----------------------------------------------------------------------------
# Optional sshd support (opt-in via ENABLE_SSHD=1 at runtime).
#
# - Hardening (no root login, no password auth, pubkey only) is baked in.
# - Runtime port and authorized_keys are wired up by entrypoint.sh.
# - Default ENABLE_SSHD=0 means the entrypoint is a pure pass-through;
#   YOLO/interactive workflows incur zero extra startup cost.
# -----------------------------------------------------------------------------
COPY --chown=root:root sshd_hardening.conf /etc/ssh/sshd_config.d/00-hardening.conf
COPY --chown=root:root entrypoint.sh       /usr/local/bin/entrypoint.sh
RUN sudo chmod 0644 /etc/ssh/sshd_config.d/00-hardening.conf \
    && sudo chmod 0755 /usr/local/bin/entrypoint.sh

ENV ENABLE_SSHD=0 \
    SSH_PORT=22

# -----------------------------------------------------------------------------
# Final
# -----------------------------------------------------------------------------
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh"]
