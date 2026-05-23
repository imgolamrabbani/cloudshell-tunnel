#!/usr/bin/env bash
# cloudshell-tunnel - 1-Click Secure Tunneling via Google Cloud Shell

set -eo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOCAL_PORT="${1:-1080}"

log_info() { echo -e "${CYAN}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[x]${NC} $1"; }

check_dependencies() {
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud SDK (gcloud) is not installed."
        echo "Please install it: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    if ! gcloud auth print-access-token &> /dev/null; then
        log_error "Not authenticated with Google Cloud."
        log_info "Run 'gcloud auth login' first."
        exit 1
    fi
}

cleanup() {
    echo ""
    log_warn "Closing tunnel and cleaning up..."
    exit 0
}

trap cleanup SIGINT

main() {
    echo -e "${GREEN}=== CloudShell Tunnel ===${NC}"
    check_dependencies

    log_info "Initializing secure tunnel on localhost:${LOCAL_PORT}..."
    log_info "Press Ctrl+C to terminate the connection."

    # FIX: Using --ssh-flag instead of bare arguments
    gcloud cloud-shell ssh --authorize-session --ssh-flag="-N" --ssh-flag="-D" --ssh-flag="${LOCAL_PORT}"
    
    log_success "Tunnel established! Configure your browser/system to use SOCKS5 on 127.0.0.1:${LOCAL_PORT}"
    
    wait
}

main
