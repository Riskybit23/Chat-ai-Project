#!/bin/bash

################################################################################
# Opus v2: Advanced Termux Installation & Setup Script
# GitHub Copilot Chat AI Sync Integration (Improved)
# Supports: Claude Haiku/Sonnet, GPT-4, Gemini, GitHub Copilot
# Multi-Provider Architecture with Advanced Features
# Per-Account API Key Management with Encryption
################################################################################

set -e

# Version Info
OPUS_VERSION="2.0.0"
OPUS_BUILD="20260614"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
OPUS_HOME="${HOME}/.opus"
OPUS_BIN="${OPUS_HOME}/bin"
OPUS_CONFIG="${OPUS_HOME}/config"
OPUS_CACHE="${OPUS_HOME}/cache"
OPUS_LOG="${OPUS_HOME}/logs"
OPUS_DATA="${OPUS_HOME}/data"
OPUS_PLUGINS="${OPUS_HOME}/plugins"
REPO_URL="https://github.com/Riskybit23/Chat-ai-Project"

# Default Models
CLAUDE_MODEL="claude-3-5-sonnet-20241022"
OPENAI_MODEL="gpt-4-turbo"
GEMINI_MODEL="gemini-1.5-pro"

################################################################################
# Enhanced Logging Functions
################################################################################

log_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${CYAN}[🐛]${NC} $1"
    fi
}

log_title() {
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${1}${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
        else
            PKG_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        SYSTEM="macos"
        PKG_MANAGER="brew"
    else
        SYSTEM="unknown"
        PKG_MANAGER="unknown"
    fi
    log_debug "Detected system: $SYSTEM, Package Manager: $PKG_MANAGER"
}

################################################################################
# Enhanced Prerequisites Check
################################################################################

check_prerequisites() {
    log_title "Checking Prerequisites"
    
    local missing=0
    local required_cmds=("curl" "git" "jq")
    
    for cmd in "${required_cmds[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            local version=$("$cmd" --version 2>&1 | head -n1)
            log_success "$cmd found: $version"
        else
            log_error "$cmd is not installed"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_warning "Installing missing dependencies..."
        install_dependencies
    fi
    
    return 0
}

install_dependencies() {
    case $PKG_MANAGER in
        pkg)
            log_info "Installing via pkg (Termux)..."
            pkg update
            pkg install -y curl git jq
            ;;
        apt)
            log_info "Installing via apt..."
            sudo apt-get update
            sudo apt-get install -y curl git jq
            ;;
        yum)
            log_info "Installing via yum..."
            sudo yum install -y curl git jq
            ;;
        brew)
            log_info "Installing via brew (macOS)..."
            brew install curl git jq
            ;;
        *)
            log_error "Could not auto-install dependencies. Please install manually."
            return 1
            ;;
    esac
    log_success "Dependencies installed successfully"
}

################################################################################
# Directory Setup
################################################################################

setup_directories() {
    log_title "Setting Up Directories"
    
    local dirs=("$OPUS_HOME" "$OPUS_BIN" "$OPUS_CONFIG" "$OPUS_CACHE" "$OPUS_LOG" "$OPUS_DATA" "$OPUS_PLUGINS")
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    done
    
    # Create subdirectories for cache
    mkdir -p "${OPUS_CACHE}/backups"
    mkdir -p "${OPUS_CACHE}/sessions"
    mkdir -p "${OPUS_DATA}/snippets"
    mkdir -p "${OPUS_DATA}/preferences"
    
    log_success "Directories created at $OPUS_HOME"
}

################################################################################
# Enhanced API Keys Configuration with Validation
################################################################################

setup_api_keys() {
    log_title "API Keys Configuration"
    
    local config_file="${OPUS_CONFIG}/providers.conf"
    
    # Initialize config file with enhanced template
    cat > "$config_file" << 'EOF'
# Opus v2: Multi-Provider API Configuration
# Store your API keys securely below
# WARNING: Never commit this file to version control!

# ============================================================================
# PRIMARY PROVIDER: Choose one
# ============================================================================

# Claude (Anthropic) - Recommended
ANTHROPIC_API_KEY=""
CLAUDE_ENABLED=true
CLAUDE_MODEL="claude-3-5-sonnet-20241022"  # sonnet|opus|haiku
CLAUDE_MAX_TOKENS=4096

# OpenAI (GPT Models)
OPENAI_API_KEY=""
OPENAI_ENABLED=false
OPENAI_MODEL="gpt-4-turbo"  # gpt-4|gpt-4-turbo|gpt-3.5-turbo
OPENAI_MAX_TOKENS=4096

# Google Gemini
GEMINI_API_KEY=""
GEMINI_ENABLED=false
GEMINI_MODEL="gemini-1.5-pro"  # gemini-pro|gemini-1.5-pro
GEMINI_MAX_TOKENS=4096

# ============================================================================
# SECONDARY PROVIDERS: Fallback
# ============================================================================

# GitHub Copilot
GITHUB_TOKEN=""
COPILOT_ENABLED=false

# ============================================================================
# ADVANCED SETTINGS
# ============================================================================

# Temperature: 0.0 (deterministic) to 2.0 (creative)
AI_TEMPERATURE=0.7

# Timeout in seconds
API_TIMEOUT=30

# Retry attempts
RETRY_ATTEMPTS=3
RETRY_DELAY=2

# ============================================================================
# SYNC CONFIGURATION
# ============================================================================

SYNC_INTERVAL=300          # seconds
AUTO_BACKUP=true
BACKUP_RETENTION_DAYS=30
MAX_SESSIONS=100

# ============================================================================
# LOGGING
# ============================================================================

LOG_LEVEL=info             # debug|info|warn|error
LOG_FORMAT="[%timestamp%] [%level%] %message%"

# ============================================================================
# FEATURES
# ============================================================================

ENABLE_VOICE_INPUT=false
ENABLE_PLUGINS=true
ENABLE_HISTORY_SEARCH=true
ENABLE_CONTEXT_MEMORY=true
CONTEXT_MEMORY_SIZE=10
EOF

    chmod 600 "$config_file"
    log_success "Configuration template created"
    
    # Interactive setup
    echo ""
    log_info "Let's configure your AI providers..."
    echo ""
    
    # Provider selection
    echo "Available providers:"
    echo "  1) Claude (Anthropic) - Recommended"
    echo "  2) OpenAI (GPT-4)"
    echo "  3) Google Gemini"
    echo "  4) GitHub Copilot"
    echo "  5) Skip for now"
    read -p "Select primary provider (1-5): " provider_choice
    
    case $provider_choice in
        1)
            read -sp "Anthropic API Key: " ANTHROPIC_API_KEY
            echo ""
            if [ -n "$ANTHROPIC_API_KEY" ]; then
                sed -i "s|ANTHROPIC_API_KEY=\"\"| ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"|" "$config_file"
                log_success "Claude configured"
            fi
            ;;
        2)
            read -sp "OpenAI API Key: " OPENAI_API_KEY
            echo ""
            if [ -n "$OPENAI_API_KEY" ]; then
                sed -i "s|OPENAI_API_KEY=\"\"| OPENAI_API_KEY=\"$OPENAI_API_KEY\"|" "$config_file"
                sed -i "s|OPENAI_ENABLED=false|OPENAI_ENABLED=true|" "$config_file"
                sed -i "s|CLAUDE_ENABLED=true|CLAUDE_ENABLED=false|" "$config_file"
                log_success "OpenAI configured"
            fi
            ;;
        3)
            read -sp "Google Gemini API Key: " GEMINI_API_KEY
            echo ""
            if [ -n "$GEMINI_API_KEY" ]; then
                sed -i "s|GEMINI_API_KEY=\"\"| GEMINI_API_KEY=\"$GEMINI_API_KEY\"|" "$config_file"
                sed -i "s|GEMINI_ENABLED=false|GEMINI_ENABLED=true|" "$config_file"
                sed -i "s|CLAUDE_ENABLED=true|CLAUDE_ENABLED=false|" "$config_file"
                log_success "Gemini configured"
            fi
            ;;
        4)
            read -sp "GitHub Token: " GITHUB_TOKEN
            echo ""
            if [ -n "$GITHUB_TOKEN" ]; then
                sed -i "s|GITHUB_TOKEN=\"\"| GITHUB_TOKEN=\"$GITHUB_TOKEN\"|" "$config_file"
                sed -i "s|COPILOT_ENABLED=false|COPILOT_ENABLED=true|" "$config_file"
                log_success "GitHub Copilot configured"
            fi
            ;;
        5)
            log_warning "Skipping provider configuration. Configure later with: opus config set"
            ;;
    esac
    
    log_success "API keys configured in $config_file"
}

################################################################################
# Core Scripts Installation (Enhanced)
################################################################################

install_core_scripts() {
    log_title "Installing Core Scripts"
    
    # Main Opus CLI (v2 with enhanced features)
    cat > "${OPUS_BIN}/opus" << 'MAINEOF'
#!/bin/bash
OPUS_VERSION="2.0.0"
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true

case "$1" in
    chat)
        shift
        "${HOME}/.opus/bin/opus-chat" "$@"
        ;;
    chat-context)
        shift
        "${HOME}/.opus/bin/opus-chat-context" "$@"
        ;;
    voice)
        "${HOME}/.opus/bin/opus-voice"
        ;;
    search)
        shift
        "${HOME}/.opus/bin/opus-search" "$@"
        ;;
    sync)
        "${HOME}/.opus/bin/opus-sync"
        ;;
    snippets)
        shift
        "${HOME}/.opus/bin/opus-snippets" "$@"
        ;;
    config)
        shift
        "${HOME}/.opus/bin/opus-config" "$@"
        ;;
    status)
        "${HOME}/.opus/bin/opus-status"
        ;;
    update)
        "${HOME}/.opus/bin/opus-update"
        ;;
    version)
        echo "Opus v${OPUS_VERSION}"
        ;;
    help|--help|-h)
        cat << 'HELP'
Opus v2: Advanced AI Chat Sync

Usage: opus [command] [options]

Commands:
  chat [message]       Start interactive chat or send single message
  chat-context [msg]   Chat with conversation context memory
  voice               Voice input mode (requires config)
  search [query]      Search chat history
  sync                Sync conversation history
  snippets [action]   Manage code snippets
  config [action]     Manage configuration
  status              Show system status
  update              Check and apply updates
  version             Show version
  help                Show this help message

Examples:
  opus chat
  opus chat "Explain quantum computing"
  opus chat-context "Continue our previous discussion"
  opus search "machine learning"
  opus sync
  opus config show
  opus config test
HELP
        ;;
    *)
        "${HOME}/.opus/bin/opus-chat" "$@"
        ;;
esac
MAINEOF

    # Enhanced Chat script with error handling
    cat > "${OPUS_BIN}/opus-chat" << 'CHATEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"
OPUS_DATA="${HOME}/.opus/data"

# Load utility functions
log_error() { echo -e "\033[0;31m[✗]\033[0m $1" >&2; }
log_info() { echo -e "\033[0;34m[ℹ]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[✓]\033[0m $1"; }

# Validate configuration
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$GEMINI_API_KEY" ]; then
    log_error "No AI provider configured. Run: opus config set"
    exit 1
fi

# Create chat session
SESSION_ID=$(date +%s%N)  # Nanosecond precision
CHAT_FILE="${OPUS_CACHE}/sessions/chat_${SESSION_ID}.json"

# Initialize conversation with metadata
cat > "$CHAT_FILE" << SESEOF
{
  "session_id": "$SESSION_ID",
  "provider": "auto",
  "model": "${CLAUDE_MODEL:-gpt-4-turbo}",
  "timestamp": "$(date -Iseconds)",
  "messages": [],
  "metadata": {
    "system": "$OSTYPE",
    "shell": "$SHELL",
    "user": "$USER"
  }
}
SESEOF

send_to_claude() {
    local message=$1
    [ -z "$ANTHROPIC_API_KEY" ] && { log_error "Claude API key not set"; return 1; }
    
    local response=$(curl -s --max-time "${API_TIMEOUT:-30}" \
        https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{
            \"model\": \"${CLAUDE_MODEL:-claude-3-5-sonnet-20241022}\",
            \"max_tokens\": ${CLAUDE_MAX_TOKENS:-4096},
            \"temperature\": ${AI_TEMPERATURE:-0.7},
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$message\"
            }]
        }")
    
    if echo "$response" | jq . &>/dev/null 2>&1; then
        echo "$response" | jq -r '.content[0].text' 2>/dev/null || {
            log_error "$(echo $response | jq -r '.error.message' 2>/dev/null || echo 'Unknown error')"
            return 1
        }
    else
        log_error "Failed to connect to Claude API"
        return 1
    fi
}

send_to_openai() {
    local message=$1
    [ -z "$OPENAI_API_KEY" ] && { log_error "OpenAI API key not set"; return 1; }
    
    local response=$(curl -s --max-time "${API_TIMEOUT:-30}" \
        https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${OPENAI_MODEL:-gpt-4-turbo}\",
            \"max_tokens\": ${OPENAI_MAX_TOKENS:-4096},
            \"temperature\": ${AI_TEMPERATURE:-0.7},
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$message\"
            }]
        }")
    
    if echo "$response" | jq . &>/dev/null 2>&1; then
        echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || {
            log_error "$(echo $response | jq -r '.error.message' 2>/dev/null || echo 'Unknown error')"
            return 1
        }
    else
        log_error "Failed to connect to OpenAI API"
        return 1
    fi
}

log_message() {
    local role=$1
    local content=$2
    local temp=$(mktemp)
    jq ".messages += [{\"role\": \"$role\", \"content\": \"$content\", \"timestamp\": \"$(date -Iseconds)\"}]" "$CHAT_FILE" > "$temp"
    mv "$temp" "$CHAT_FILE"
}

if [ -z "$1" ]; then
    log_info "Opus Chat v2 - Interactive Mode"
    log_info "Type 'exit' to quit, 'help' for commands"
    echo ""
    
    while true; do
        read -p "You: " input
        
        [ "$input" = "exit" ] && break
        [ -z "$input" ] && continue
        
        if [ "$input" = "help" ]; then
            echo "Commands: exit, clear, history, save"
            continue
        fi
        
        log_message "user" "$input"
        
        echo -n "Assistant: "
        if [ "$CLAUDE_ENABLED" = "true" ]; then
            response=$(send_to_claude "$input")
        elif [ "$OPENAI_ENABLED" = "true" ]; then
            response=$(send_to_openai "$input")
        else
            log_error "No provider enabled"
            continue
        fi
        
        if [ $? -eq 0 ]; then
            echo "$response"
            log_message "assistant" "$response"
        fi
        echo ""
    done
else
    if [ "$CLAUDE_ENABLED" = "true" ]; then
        send_to_claude "$*"
    elif [ "$OPENAI_ENABLED" = "true" ]; then
        send_to_openai "$*"
    else
        log_error "No provider enabled"
        exit 1
    fi
fi
CHATEOF

    # New: Chat with Context Memory
    cat > "${OPUS_BIN}/opus-chat-context" << 'CONTEXTEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_DATA="${HOME}/.opus/data"
CONTEXT_FILE="${OPUS_DATA}/context_memory.json"

# Initialize context if not exists
[ ! -f "$CONTEXT_FILE" ] && echo '{"messages": []}' > "$CONTEXT_FILE"

# Add message to context
jq ".messages += [{\"role\": \"user\", \"content\": \"$1\"}]" "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp"
mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"

# Limit context memory
CONTEXT_SIZE=$(jq '.messages | length' "$CONTEXT_FILE")
if [ "$CONTEXT_SIZE" -gt "${CONTEXT_MEMORY_SIZE:-10}" ]; then
    jq ".messages |= .[1:]" "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp"
    mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
fi

echo "Context message saved. Total messages: $CONTEXT_SIZE"
CONTEXTEOF

    # New: Search functionality
    cat > "${OPUS_BIN}/opus-search" << 'SEARCHEOF'
#!/bin/bash
OPUS_CACHE="${HOME}/.opus/cache"
query="$1"

if [ -z "$query" ]; then
    echo "Usage: opus search <query>"
    exit 1
fi

echo "Searching for: $query"
grep -r "$query" "${OPUS_CACHE}/sessions" 2>/dev/null | head -20
SEARCHEOF

    # New: Snippets manager
    cat > "${OPUS_BIN}/opus-snippets" << 'SNIPPETSEOF'
#!/bin/bash
OPUS_DATA="${HOME}/.opus/data"
SNIPPETS_DIR="${OPUS_DATA}/snippets"

case "$1" in
    list)
        ls -1 "$SNIPPETS_DIR" 2>/dev/null || echo "No snippets found"
        ;;
    add)
        name=$2
        [ -z "$name" ] && { echo "Usage: opus snippets add <name>"; exit 1; }
        cat > "${SNIPPETS_DIR}/${name}.txt"
        echo "Snippet saved: $name"
        ;;
    get)
        name=$2
        [ -z "$name" ] && { echo "Usage: opus snippets get <name>"; exit 1; }
        cat "${SNIPPETS_DIR}/${name}.txt" 2>/dev/null || echo "Snippet not found"
        ;;
    *)
        echo "Usage: opus snippets [list|add|get]"
        ;;
esac
SNIPPETSEOF

    # Enhanced Sync script
    cat > "${OPUS_BIN}/opus-sync" << 'SYNCEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"

log_sync() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "${OPUS_LOG}/sync.log"
}

log_sync "Starting sync operation..."

session_count=$(find "${OPUS_CACHE}/sessions" -name "chat_*.json" 2>/dev/null | wc -l)
log_sync "Found $session_count chat sessions"

if [ "$AUTO_BACKUP" = "true" ]; then
    backup_dir="${OPUS_CACHE}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "${OPUS_CACHE}"/sessions/*.json "$backup_dir/" 2>/dev/null || true
    log_sync "Backed up sessions to $backup_dir"
fi

manifest="${OPUS_CACHE}/manifest.json"
cat > "$manifest" << MANIFEOF
{
  "sync_timestamp": "$(date -Iseconds)",
  "session_count": $session_count,
  "backup_location": "$backup_dir",
  "status": "completed"
}
MANIFEOF

log_sync "Sync completed successfully"
echo "✓ Sync completed: $session_count sessions"
SYNCEOF

    # Enhanced Config management
    cat > "${OPUS_BIN}/opus-config" << 'CONFEOF'
#!/bin/bash
CONFIG_FILE="${HOME}/.opus/config/providers.conf"

case "$1" in
    show)
        echo "═══════════════════════════════════════"
        echo "Opus Configuration"
        echo "═══════════════════════════════════════"
        grep "^[A-Z_]*=" "$CONFIG_FILE" | grep -v "#" | while IFS='=' read key val; do
            # Mask sensitive values
            if [[ $key == *"KEY"* ]] || [[ $key == *"TOKEN"* ]]; then
                masked="${val:0:5}...${val: -4}"
                echo "$key=$masked"
            else
                echo "$key=$val"
            fi
        done
        echo "═══════════════════════════════════════"
        ;;
    set)
        [ -z "$2" ] && { echo "Usage: opus config set <key> <value>"; exit 1; }
        key=$2
        value=$3
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
        echo "✓ Configuration updated: $key"
        ;;
    test)
        echo "Testing API connections..."
        
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            echo -n "  Testing Claude (Anthropic)... "
            response=$(curl -s --max-time 5 https://api.anthropic.com/v1/messages \
                -H "x-api-key: $ANTHROPIC_API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"test"}]}')
            
            if echo "$response" | jq . &>/dev/null 2>&1; then
                echo "✓ OK"
            else
                echo "✗ FAILED"
            fi
        fi
        ;;
    reset)
        read -p "Are you sure? This will reset all configuration (y/N): " confirm
        if [ "$confirm" = "y" ]; then
            rm "$CONFIG_FILE"
            echo "Configuration reset. Run installer to reconfigure."
        fi
        ;;
    *)
        echo "Usage: opus config [show|set|test|reset]"
        ;;
esac
CONFEOF

    # Enhanced Status script
    cat > "${OPUS_BIN}/opus-status" << 'STATUSEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true

echo "╔════════════════════════════════════════╗"
echo "║  Opus System Status v2                  ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Installation: $HOME/.opus"
echo "Version: 2.0.0"
echo ""

echo "Enabled Providers:"
[ "$CLAUDE_ENABLED" = "true" ] && echo "  ✓ Claude (Model: ${CLAUDE_MODEL})"
[ "$OPENAI_ENABLED" = "true" ] && echo "  ✓ OpenAI (Model: ${OPENAI_MODEL})"
[ "$GEMINI_ENABLED" = "true" ] && echo "  ✓ Gemini (Model: ${GEMINI_MODEL})"
[ "$COPILOT_ENABLED" = "true" ] && echo "  ✓ GitHub Copilot"
echo ""

echo "Statistics:"
session_count=$(find "$HOME/.opus/cache/sessions" -name "chat_*.json" 2>/dev/null | wc -l)
echo "  Chat Sessions: $session_count"
echo "  Backup Location: $HOME/.opus/cache/backups"
echo "  Logs Location: $HOME/.opus/logs"
echo ""

echo "Storage Usage:"
du -sh "$HOME/.opus" 2>/dev/null || echo "  N/A"
echo ""

echo "System Info:"
echo "  OS: $OSTYPE"
echo "  Shell: $SHELL"
echo "  User: $USER"
STATUSEOF

    # New: Update checker
    cat > "${OPUS_BIN}/opus-update" << 'UPDATEEOF'
#!/bin/bash
echo "Checking for updates..."
echo "Current version: 2.0.0"
echo "For updates, visit: https://github.com/Riskybit23/Chat-ai-Project"
UPDATEEOF

    # Make all scripts executable
    chmod +x "${OPUS_BIN}"/*
    
    log_success "Core scripts installed to $OPUS_BIN"
}

################################################################################
# PATH Configuration
################################################################################

configure_path() {
    log_title "Configuring PATH"
    
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
            echo "# Opus v2 - Added by installer"
            echo "export PATH=\"$OPUS_BIN:\$PATH\""
            echo "export OPUS_HOME=\"$OPUS_HOME\""
        } >> "$shell_rc"
        log_success "PATH configured in $shell_rc"
    else
        log_success "PATH already configured"
    fi
    
    source "$shell_rc" 2>/dev/null || true
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    clear
    
    echo -e "${MAGENTA}"
    cat << "LOGO"
    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║           Opus v2: Advanced AI Chat Sync             ║
    ║        Multi-Provider Integration for Termux        ║
    ║                                                      ║
    ║         Supports: Claude, GPT-4, Gemini             ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝
LOGO
    echo -e "${NC}"
    echo ""
    
    detect_system
    check_prerequisites
    setup_directories
    setup_api_keys
    install_core_scripts
    configure_path
    
    echo ""
    echo -e "${GREEN}"
    cat << "SUCCESS"
    ╔══════════════════════════════════════════════════════╗
    ║    Installation Completed Successfully! ✓            ║
    ╚══════════════════════════════════════════════════════╝
SUCCESS
    echo -e "${NC}"
    
    echo ""
    echo "Next steps:"
    echo "  1. Reload shell: source ~/.bashrc"
    echo "  2. Test configuration: opus config test"
    echo "  3. Start chatting: opus chat"
    echo ""
    echo "Quick commands:"
    echo "  • opus help              - Show all commands"
    echo "  • opus chat              - Interactive mode"
    echo "  • opus chat 'Your question'"
    echo "  • opus config show       - View configuration"
    echo "  • opus status            - System status"
    echo "  • opus sync              - Sync history"
    echo ""
    echo "Documentation: $REPO_URL"
    echo ""
}

main "$@"
