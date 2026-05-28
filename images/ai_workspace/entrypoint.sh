#!/usr/bin/env bash
# =============================================================================
# entrypoint.sh -- ai_workspace container entrypoint.
#
# Default behavior: pass-through. Just exec the CMD (typically zsh) with no
# extra setup, so the YOLO/interactive workflows pay zero startup overhead.
#
# Opt-in: when ENABLE_SSHD=1, prepare and start sshd in the background
# before handing control to CMD. This is intended for VSCode Dev Containers
# / Remote-SSH workflows where the host attaches to the container over SSH.
#
# Environment variables (only relevant when ENABLE_SSHD=1):
#   SSH_PORT              TCP port for sshd (default: 22).
#   SSH_AUTHORIZED_KEYS   Optional. If $HOME/.ssh/authorized_keys does not
#                         already exist (e.g. via bind mount), this value is
#                         written verbatim into it. One key per line.
#
# Hardening (PermitRootLogin no, PasswordAuthentication no, pubkey-only) is
# baked into /etc/ssh/sshd_config.d/00-hardening.conf at image build time
# and is NOT configurable here.
# =============================================================================

# No `set -e`: failures in the optional sshd setup must not prevent the
# main CMD from running. Each step handles its own errors explicitly.
set -u

log()  { printf '[entrypoint] %s\n' "$*" >&2; }
warn() { printf '[entrypoint] WARN: %s\n' "$*" >&2; }

start_sshd() {
    # 1. Host keys. Generated per-container on first start so multiple
    #    containers from the same image do not share identity.
    if ! ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
        log "generating host keys"
        sudo ssh-keygen -A >/dev/null 2>&1 \
            || { warn "ssh-keygen -A failed; sshd will not start"; return 1; }
    fi

    # 2. Runtime port. Written as a separate drop-in so the hardening
    #    snippet stays untouched and re-runs (docker restart) are safe.
    local port="${SSH_PORT:-22}"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        warn "invalid SSH_PORT='$port'; falling back to 22"
        port=22
    fi
    echo "Port ${port}" \
        | sudo tee /etc/ssh/sshd_config.d/10-port.conf >/dev/null \
        || { warn "failed to write port config; sshd will not start"; return 1; }

    # 3. authorized_keys. Bind-mount wins; ENV is fallback; otherwise warn.
    local ak="${HOME}/.ssh/authorized_keys"
    mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
    if [[ -s "$ak" ]]; then
        log "authorized_keys already populated; leaving as-is"
    elif [[ -n "${SSH_AUTHORIZED_KEYS:-}" ]]; then
        printf '%s\n' "$SSH_AUTHORIZED_KEYS" > "$ak" \
            && chmod 600 "$ak" \
            && log "wrote authorized_keys from \$SSH_AUTHORIZED_KEYS" \
            || warn "failed to write authorized_keys"
    else
        warn "no authorized_keys: nobody will be able to log in over SSH"
    fi

    # 4. Launch. sshd daemonizes by default; non-zero exit means it failed
    #    to start (port in use, config error, etc.).
    if sudo /usr/sbin/sshd; then
        log "sshd listening on port ${port}"
    else
        warn "sshd failed to start"
        return 1
    fi
}

if [[ "${ENABLE_SSHD:-0}" == "1" ]]; then
    start_sshd || warn "sshd setup failed; container will continue without SSH"
fi

# Hand off to the original CMD. Replace the shell so signal semantics
# (SIGTERM, etc.) match what the user wrote in their CMD.
if [[ $# -eq 0 ]]; then
    warn "no command to exec; this is unexpected. Sleeping forever."
    exec sleep infinity
fi
exec "$@"
