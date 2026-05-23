#!/usr/bin/env bash
# cloudshell-tunnel - 1-Click System-Wide Secure Tunneling

set -eo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOCAL_PORT="${1:-1080}"
ACTIVE_SERVICE=""

log_info() { echo -e "${CYAN}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[x]${NC} $1"; }

check_dependencies() {
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud SDK is not installed."
        exit 1
    fi
    if ! gcloud auth print-access-token &> /dev/null; then
        log_error "Not authenticated. Run 'gcloud auth login' first."
        exit 1
    fi
}

get_active_network() {
    # Get the default route interface (e.g., en0)
    local interface=$(route get default 2>/dev/null | awk '/interface/ {print $2}')
    if [[ -n "$interface" ]]; then
        # Robustly extract just the hardware port name, ignoring the (1) or (4) prefixes
        ACTIVE_SERVICE=$(networksetup -listnetworkserviceorder | grep -B 1 "Device: $interface" | head -n 1 | awk -F'\\) ' '{print $2}')
    fi
    
    # Fallback just in case
    if [[ -z "$ACTIVE_SERVICE" ]]; then
        ACTIVE_SERVICE="Wi-Fi"
    fi
}

enable_proxy() {
    log_info "Routing entire Mac through '$ACTIVE_SERVICE' via SOCKS5..."
    sudo networksetup -setsocksfirewallproxy "$ACTIVE_SERVICE" 127.0.0.1 "$LOCAL_PORT"
    sudo networksetup -setsocksfirewallproxystate "$ACTIVE_SERVICE" on
    log_success "System proxy enabled! All apps are now routed securely."
}

disable_proxy() {
    echo ""
    if [[ -n "$ACTIVE_SERVICE" ]]; then
        log_warn "Reverting macOS system proxy on '$ACTIVE_SERVICE'..."
        sudo networksetup -setsocksfirewallproxystate "$ACTIVE_SERVICE" off
        log_success "System proxy disabled. You are back on your normal ISP."
    fi
    
    # Kill the SSH tunnel cleanly
    pkill -f "ssh.*-D $LOCAL_PORT" 2>/dev/null || true
    exit 0
}

# Trap Ctrl+C to ensure we cleanly disable the system proxy
trap disable_proxy SIGINT

main() {
    echo -e "${GREEN}=== CloudShell Tunnel (System-Wide) ===${NC}"
    check_dependencies
    get_active_network

    log_info "Initializing secure tunnel on localhost:${LOCAL_PORT}..."
    
    # Start SSH. -f puts it in background AFTER asking for password.
    gcloud cloud-shell ssh --authorize-session --ssh-flag="-N" --ssh-flag="-f" --ssh-flag="-D" --ssh-flag="${LOCAL_PORT}"
    
    log_info "Waiting for tunnel to open..."
    while ! nc -z 127.0.0.1 "$LOCAL_PORT" >/dev/null 2>&1; do
        sleep 1
    done

    # Port is open, hijack the system routing
    enable_proxy
    
    log_info "Press Ctrl+C to terminate the connection and revert settings."

    # Keep script running to catch the trap
    while true; do sleep 86400; done
}

main
