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
TUNNEL_PID=""

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
    local interface=$(route get default 2>/dev/null | awk '/interface/ {print $2}')
    if [[ -n "$interface" ]]; then
        # Extracts the human-readable service name (e.g., "Wi-Fi") based on the active interface
        ACTIVE_SERVICE=$(networksetup -listnetworkserviceorder | grep -B 1 "$interface" | head -n 1 | sed -E 's/^\([0-9]+\)\s+//')
    else
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
    
    # Kill the background SSH process if it's still running
    if [[ -n "$TUNNEL_PID" ]]; then
        kill "$TUNNEL_PID" 2>/dev/null || true
    fi
    exit 0
}

# Trap Ctrl+C to ensure we cleanly disable the system proxy
trap disable_proxy SIGINT

main() {
    echo -e "${GREEN}=== CloudShell Tunnel (System-Wide) ===${NC}"
    check_dependencies
    get_active_network

    log_info "Initializing secure tunnel on localhost:${LOCAL_PORT}..."
    
    # Start the SSH tunnel in the background
    gcloud cloud-shell ssh --authorize-session --ssh-flag="-N" --ssh-flag="-D" --ssh-flag="${LOCAL_PORT}" &
    TUNNEL_PID=$!

    log_info "Waiting for Google Cloud to provision the instance and open the port..."
    
    # Wait until the port actually opens before hijacking the network
    while ! nc -z 127.0.0.1 "$LOCAL_PORT" >/dev/null 2>&1; do
        sleep 1
    done

    # Port is open, hijack the system routing
    enable_proxy
    
    log_info "Press Ctrl+C to terminate the connection and revert settings."

    # Keep the script running to hold the trap open
    wait $TUNNEL_PID
}

main
