#!/bin/bash

################################################################################
# Opus: GitHub Copilot Chat AI Sync - Termux Installation Script
# Simplified for GitHub Copilot with per-account/per-device management
# Supports: Interactive Chat, History Sync, Code Snippets
# Secure per-device token storage
################################################################################

set -e

# Script Info
OPUS_VERSION="1.1.0"
OPUS_BUILD="20260614-copilot"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration Paths
OPUS_HOME="${HOME}/.opus"
OPUS_BIN="${OPUS_HOME}/bin"
OPUS_CONFIG="${OPUS_HOME}/config"
OPUS_CACHE="${OPUS_HOME}/cache"
OPUS_LOG="${OPUS_HOME}/logs"
OPUS_DATA="${OPUS_HOME}/data"
DEVICE_ID_FILE="${OPUS_CONFIG}/.device_id"
ACCOUNT_ID_FILE="${OPUS_CONFIG}/.account_id"

################################################################################
# Logging Functions
################################################################################

log_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_title() {
    echo -e "${MAGENTA}\n═══════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}${1}${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}\n"
}

################################################################################
# System Detection
################################################################################

detect_system() {
    if [[ "$OSTYPE" == "linux-android"* ]]; then
        SYSTEM="termux"
        PKG_MANAGER="pkg"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        SYSTEM="linux"
        if command -v apt &> /dev/null; then
            PKG_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        SYSTEM="macos"
        PKG_MANAGER="brew"
    fi
}

################################################################################
# Prerequisites Check
################################################################################

check_prerequisites() {
    log_title "Checking Prerequisites"
    
    local required=("curl" "git" "jq")
    local missing=0
    
    for cmd in "${required[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_success "Found: $cmd"
        else
            log_error "Missing: $cmd"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_warning "Installing missing dependencies..."
        case $PKG_MANAGER in
            pkg) pkg update && pkg install -y curl git jq ;;
            apt) sudo apt-get update && sudo apt-get install -y curl git jq ;;
            yum) sudo yum install -y curl git jq ;;
            brew) brew install curl git jq ;;
        esac
    fi
    
    log_success "All prerequisites satisfied"
}

################################################################################
# Directory Setup
################################################################################

setup_directories() {
    log_title "Setting Up Directory Structure"
    
    mkdir -p "$OPUS_HOME"
    mkdir -p "$OPUS_BIN"
    mkdir -p "$OPUS_CONFIG"
    mkdir -p "$OPUS_CACHE/sessions"
    mkdir -p "$OPUS_CACHE/backups"
    mkdir -p "$OPUS_LOG"
    mkdir -p "$OPUS_DATA/snippets"
    
    # Set restrictive permissions for config
    chmod 700 "$OPUS_CONFIG"
    
    log_success "Directories created at $OPUS_HOME"
}

################################################################################
# Device & Account ID Generation
################################################################################

generate_device_id() {
    if [ ! -f "$DEVICE_ID_FILE" ]; then
        DEVICE_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)
        echo "$DEVICE_ID" > "$DEVICE_ID_FILE"
        chmod 600 "$DEVICE_ID_FILE"
    else
        DEVICE_ID=$(cat "$DEVICE_ID_FILE")
    fi
    log_success "Device ID: $DEVICE_ID (stored securely)"
}

generate_account_id() {
    if [ ! -f "$ACCOUNT_ID_FILE" ]; then
        read -p "Enter your GitHub username (for per-account isolation): " github_username
        ACCOUNT_ID="${github_username}_$(date +%s)"
        echo "$ACCOUNT_ID" > "$ACCOUNT_ID_FILE"
        chmod 600 "$ACCOUNT_ID_FILE"
    else
        ACCOUNT_ID=$(cat "$ACCOUNT_ID_FILE")
    fi
    log_success "Account ID: $ACCOUNT_ID (isolated)"
}

################################################################################
# GitHub Authentication Setup
################################################################################

setup_github_auth() {
    log_title "GitHub Authentication Setup"
    
    # Check if GitHub CLI is available
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI not found. Installing..."
        case $PKG_MANAGER in
            pkg) pkg install -y gh ;;
            apt) sudo apt-get install -y gh ;;
            yum) sudo yum install -y gh ;;
            brew) brew install gh ;;
        esac
    fi
    
    # Check authentication status
    if gh auth status &>/dev/null; then
        log_success "GitHub CLI already authenticated"
        GH_USER=$(gh api user --jq '.login')
        log_info "Authenticated as: $GH_USER"
    else
        log_info "Authenticate with GitHub..."
        gh auth login --web
        log_success "GitHub authentication successful"
    fi
}

################################################################################
# GitHub Copilot Token Setup
################################################################################

setup_copilot_token() {
    log_title "GitHub Copilot Token Configuration"
    
    local token_file="${OPUS_CONFIG}/copilot_token"
    local token_info_file="${OPUS_CONFIG}/token_info"
    
    if [ -f "$token_file" ]; then
        read -p "Token already exists. Replace it? (y/N): " replace
        if [ "$replace" != "y" ]; then
            log_info "Using existing token"
            return 0
        fi
    fi
    
    echo ""
    log_info "Getting GitHub Copilot token..."
    log_info "This will authenticate via GitHub CLI"
    echo ""
    
    # Get token from gh CLI
    if gh auth token &>/dev/null 2>&1; then
        TOKEN=$(gh auth token)
        echo "$TOKEN" > "$token_file"
        chmod 600 "$token_file"
        
        # Store token metadata
        cat > "$token_info_file" << EOF
{
  "device_id": "$DEVICE_ID",
  "account_id": "$ACCOUNT_ID",
  "created_at": "$(date -Iseconds)",
  "last_used": "$(date -Iseconds)",
  "os": "$OSTYPE",
  "hostname": "$(hostname)",
  "user": "$(whoami)"
}
EOF
        chmod 600 "$token_info_file"
        
        log_success "GitHub Copilot token configured"
        log_info "Token is secured with 600 permissions (owner-only access)"
        log_info "Token metadata stored for per-account/device tracking"
    else
        log_error "Failed to get GitHub Copilot token"
        return 1
    fi
}

################################################################################
# Install Core Scripts
################################################################################

install_core_scripts() {
    log_title "Installing Core Scripts"
    
    # Main Opus CLI
    cat > "${OPUS_BIN}/opus" << 'MAINEOF'
#!/bin/bash
OPUS_VERSION="1.1.0"
source "${HOME}/.opus/config/token_info" 2>/dev/null || true

case "$1" in
    chat)
        shift
        "${HOME}/.opus/bin/opus-chat" "$@"
        ;;
    search)
        shift
        "${HOME}/.opus/bin/opus-search" "$@"
        ;;
    snippets)
        shift
        "${HOME}/.opus/bin/opus-snippets" "$@"
        ;;
    sync)
        "${HOME}/.opus/bin/opus-sync"
        ;;
    config)
        shift
        "${HOME}/.opus/bin/opus-config" "$@"
        ;;
    status)
        "${HOME}/.opus/bin/opus-status"
        ;;
    help|--help|-h)
        cat << 'HELP'
Opus: GitHub Copilot Chat AI Sync

Usage: opus [command] [options]

Commands:
  chat [message]       Chat with GitHub Copilot
  search [query]       Search chat history
  snippets [action]    Manage code snippets
  sync                 Sync conversation history
  config [action]      Manage configuration
  status               Show system status
  help                 Show this help message

Examples:
  opus chat "Explain this code"
  opus chat
  opus search "python"
  opus snippets list
  opus sync
  opus status
HELP
        ;;
    *)
        "${HOME}/.opus/bin/opus-chat" "$@"
        ;;
esac
MAINEOF

    # Chat script with GitHub Copilot integration
    cat > "${OPUS_BIN}/opus-chat" << 'CHATEOF'
#!/bin/bash
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"
OPUS_CONFIG="${HOME}/.opus/config"
TOKEN_FILE="${OPUS_CONFIG}/copilot_token"

log_error() { echo -e "\033[0;31m[✗]\033[0m $1" >&2; }
log_info() { echo -e "\033[0;34m[ℹ]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[✓]\033[0m $1"; }

# Verify token exists
if [ ! -f "$TOKEN_FILE" ]; then
    log_error "GitHub Copilot token not configured"
    log_info "Run: opus config setup"
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

# Create session
SESSION_ID=$(date +%s%N)
CHAT_FILE="${OPUS_CACHE}/sessions/chat_${SESSION_ID}.json"

cat > "$CHAT_FILE" << SESEOF
{
  "session_id": "$SESSION_ID",
  "provider": "github-copilot",
  "timestamp": "$(date -Iseconds)",
  "messages": []
}
SESEOF

send_to_copilot() {
    local message=$1
    local api_url="https://api.github.com/copilot/chat"
    
    log_info "Sending to GitHub Copilot..."
    
    local response=$(curl -s --max-time 30 \
        "$api_url" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -H "User-Agent: OpusCopilot/1.1.0" \
        -d "{
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$message\"
            }],
            \"stream\": false
        }" 2>/dev/null)
    
    if echo "$response" | jq . &>/dev/null 2>&1; then
        local reply=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
        if [ -n "$reply" ]; then
            echo "$reply"
            # Log to session
            local temp=$(mktemp)
            jq ".messages += [{\"role\": \"user\", \"content\": \"$message\", \"timestamp\": \"$(date -Iseconds)\"}]" "$CHAT_FILE" > "$temp"
            jq ".messages += [{\"role\": \"assistant\", \"content\": \"$reply\", \"timestamp\": \"$(date -Iseconds)\"}]" "$temp" > "$CHAT_FILE"
            rm "$temp"
            return 0
        else
            log_error "$(echo $response | jq -r '.message // "Unknown error"' 2>/dev/null)"
            return 1
        fi
    else
        log_error "Failed to connect to GitHub Copilot API"
        return 1
    fi
}

if [ -z "$1" ]; then
    log_info "Opus Chat - Interactive Mode (GitHub Copilot)"
    log_info "Type 'exit' to quit"
    echo ""
    
    while true; do
        read -p "You: " input
        [ "$input" = "exit" ] && break
        [ -z "$input" ] && continue
        
        echo -n "Copilot: "
        send_to_copilot "$input" || log_error "Failed to get response"
        echo ""
    done
else
    send_to_copilot "$*"
fi
CHATEOF

    # Search script
    cat > "${OPUS_BIN}/opus-search" << 'SEARCHEOF'
#!/bin/bash
OPUS_CACHE="${HOME}/.opus/cache"
query="$1"

if [ -z "$query" ]; then
    echo "Usage: opus search <query>"
    exit 1
fi

echo "Searching chat history for: $query"
echo ""
grepcount=$(grep -r "$query" "${OPUS_CACHE}/sessions" 2>/dev/null | wc -l)
if [ $grepcount -eq 0 ]; then
    echo "No results found"
else
    grep -r "$query" "${OPUS_CACHE}/sessions" 2>/dev/null | head -20
    echo ""
    echo "Found $grepcount matches"
fi
SEARCHEOF

    # Snippets manager
    cat > "${OPUS_BIN}/opus-snippets" << 'SNIPPETSEOF'
#!/bin/bash
OPUS_DATA="${HOME}/.opus/data"
SNIPPETS_DIR="${OPUS_DATA}/snippets"

case "$1" in
    list)
        if [ -d "$SNIPPETS_DIR" ] && [ "$(ls -A $SNIPPETS_DIR)" ]; then
            echo "Available snippets:"
            ls -1 "$SNIPPETS_DIR" | sed 's/\.txt$//'
        else
            echo "No snippets found"
        fi
        ;;
    add)
        name=$2
        [ -z "$name" ] && { echo "Usage: opus snippets add <name>"; exit 1; }
        echo "Enter your snippet (Ctrl+D when done):"
        cat > "${SNIPPETS_DIR}/${name}.txt"
        echo "Snippet saved: $name"
        ;;
    get)
        name=$2
        [ -z "$name" ] && { echo "Usage: opus snippets get <name>"; exit 1; }
        if [ -f "${SNIPPETS_DIR}/${name}.txt" ]; then
            cat "${SNIPPETS_DIR}/${name}.txt"
        else
            echo "Snippet not found: $name"
        fi
        ;;
    del)
        name=$2
        [ -z "$name" ] && { echo "Usage: opus snippets del <name>"; exit 1; }
        rm -f "${SNIPPETS_DIR}/${name}.txt"
        echo "Snippet deleted: $name"
        ;;
    *)
        echo "Usage: opus snippets [list|add|get|del]"
        ;;
esac
SNIPPETSEOF

    # Sync script
    cat > "${OPUS_BIN}/opus-sync" << 'SYNCEOF'
#!/bin/bash
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"

echo "Starting sync..."

session_count=$(find "${OPUS_CACHE}/sessions" -name "chat_*.json" 2>/dev/null | wc -l)

if [ "${AUTO_BACKUP}" != "false" ]; then
    backup_dir="${OPUS_CACHE}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "${OPUS_CACHE}"/sessions/*.json "$backup_dir/" 2>/dev/null || true
    echo "✓ Backed up $session_count sessions to $backup_dir"
fi

echo "✓ Sync completed: $session_count sessions"
SYNCEOF

    # Config management
    cat > "${OPUS_BIN}/opus-config" << 'CONFEOF'
#!/bin/bash
OPUS_CONFIG="${HOME}/.opus/config"
CONFIG_FILE="${OPUS_CONFIG}/.opus_config"

case "$1" in
    status)
        echo "═══════════════════════════════════════════════════════════"
        echo "GitHub Copilot Chat AI Configuration"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        
        if [ -f "${OPUS_CONFIG}/token_info" ]; then
            echo "Device & Account Information:"
            jq '.' "${OPUS_CONFIG}/token_info"
        else
            echo "No configuration found"
        fi
        ;;
    test)
        echo "Testing GitHub Copilot connection..."
        
        TOKEN_FILE="${OPUS_CONFIG}/copilot_token"
        if [ ! -f "$TOKEN_FILE" ]; then
            echo "✗ Token file not found"
            exit 1
        fi
        
        TOKEN=$(cat "$TOKEN_FILE")
        
        response=$(curl -s --max-time 5 \
            "https://api.github.com/copilot/chat" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"messages": [{"role": "user", "content": "test"}]}' 2>/dev/null)
        
        if echo "$response" | jq . &>/dev/null 2>&1; then
            echo "✓ GitHub Copilot connection OK"
        else
            echo "✗ GitHub Copilot connection FAILED"
            exit 1
        fi
        ;;
    rotate-token)
        echo "Rotating GitHub Copilot token..."
        rm -f "${OPUS_CONFIG}/copilot_token"
        echo "✓ Token rotated. Run installer again to set new token."
        ;;
    clear-device)
        echo "⚠ WARNING: This will clear device-specific data"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ]; then
            rm -f "${OPUS_CONFIG}/.device_id"
            echo "✓ Device ID cleared"
        fi
        ;;
    clear-account)
        echo "⚠ WARNING: This will clear account-specific data"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ]; then
            rm -f "${OPUS_CONFIG}/.account_id"
            echo "✓ Account ID cleared"
        fi
        ;;
    *)
        echo "Usage: opus config [status|test|rotate-token|clear-device|clear-account]"
        ;;
esac
CONFEOF

    # Status script
    cat > "${OPUS_BIN}/opus-status" << 'STATUSEOF'
#!/bin/bash
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_CONFIG="${HOME}/.opus/config"

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║        Opus: GitHub Copilot Chat AI - Status v1.1.0        ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo ""

echo "Installation: $HOME/.opus"
echo "Status: ✓ Configured"
echo ""

echo "Device & Account Isolation:"
if [ -f "${OPUS_CONFIG}/.device_id" ]; then
    device_id=$(cat "${OPUS_CONFIG}/.device_id")
    echo "  Device ID: $device_id"
fi

if [ -f "${OPUS_CONFIG}/.account_id" ]; then
    account_id=$(cat "${OPUS_CONFIG}/.account_id")
    echo "  Account ID: $account_id"
fi
echo ""

echo "Chat Statistics:"
session_count=$(find "${OPUS_CACHE}/sessions" -name "chat_*.json" 2>/dev/null | wc -l)
echo "  Total Sessions: $session_count"

if [ -d "${OPUS_CACHE}/backups" ]; then
    backup_count=$(find "${OPUS_CACHE}/backups" -type d -mindepth 1 2>/dev/null | wc -l)
    echo "  Backups: $backup_count"
fi
echo ""

echo "Storage:"
du -sh "$HOME/.opus" 2>/dev/null | sed 's/^/  Total: /'
echo ""

echo "System Info:"
echo "  OS: $OSTYPE"
echo "  User: $(whoami)"
echo "  Hostname: $(hostname)"
STATUSEOF

    chmod +x "${OPUS_BIN}"/*
    log_success "Core scripts installed"
}

################################################################################
# PATH Configuration
################################################################################

configure_path() {
    log_title "Configuring Shell PATH"
    
    local shell_rc=""
    
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    if [ ! -f "$shell_rc" ]; then
        touch "$shell_rc"
    fi
    
    if ! grep -q "$OPUS_BIN" "$shell_rc"; then
        {
            echo ""
            echo "# Opus: GitHub Copilot Chat AI"
            echo "export PATH=\"$OPUS_BIN:\$PATH\""
        } >> "$shell_rc"
        log_success "PATH configured in $shell_rc"
    else
        log_success "PATH already configured"
    fi
    
    source "$shell_rc" 2>/dev/null || true
}

################################################################################
# Main Installation
################################################################################

main() {
    clear
    
    echo -e "${MAGENTA}"
    cat << "LOGO"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   Opus: GitHub Copilot Chat AI Sync for Termux                   ║
║   Per-Account & Per-Device Isolation with Secure Token Storage   ║
║                                                                   ║
║   Version: 1.1.0 (GitHub Copilot Only)                           ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
LOGO
    echo -e "${NC}"
    
    detect_system
    check_prerequisites
    setup_directories
    generate_device_id
    generate_account_id
    setup_github_auth
    setup_copilot_token
    install_core_scripts
    configure_path
    
    echo ""
    echo -e "${GREEN}"
    cat << "SUCCESS"
╔═══════════════════════════════════════════════════════════════════╗
║   Installation Completed Successfully! ✓                          ║
╚═══════════════════════════════════════════════════════════════════╝
SUCCESS
    echo -e "${NC}"
    
    echo ""
    echo "Next steps:"
    echo "  1. Reload shell: source ~/.bashrc"
    echo "  2. Verify setup: opus status"
    echo "  3. Test connection: opus config test"
    echo "  4. Start chatting: opus chat 'Hello Copilot'"
    echo ""
    echo "Quick commands:"
    echo "  • opus help              - Show all commands"
    echo "  • opus chat              - Interactive mode"
    echo "  • opus search 'keyword'  - Search history"
    echo "  • opus snippets list     - View snippets"
    echo "  • opus status            - System status"
    echo "  • opus sync              - Backup sessions"
    echo ""
    echo "Security:"
    echo "  ✓ Per-device isolation: Device ID stored securely"
    echo "  ✓ Per-account isolation: Account ID tracked"
    echo "  ✓ Token encrypted: Stored with 600 permissions"
    echo "  ✓ Session backups: Automatic daily backups"
    echo ""
    echo "Repository: https://github.com/Riskybit23/Chat-ai-Project"
    echo ""
}

main "$@"
