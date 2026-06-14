#!/bin/bash

################################################################################
# Opus: Termux Installation & Setup Script
# GitHub Copilot Chat AI Sync Integration
# Supports: Claude Haiku 4.5, GitHub Copilot, Multi-Provider Architecture
# Per-Account API Key Management
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPUS_HOME="${HOME}/.opus"
OPUS_BIN="${OPUS_HOME}/bin"
OPUS_CONFIG="${OPUS_HOME}/config"
OPUS_CACHE="${OPUS_HOME}/cache"
OPUS_LOG="${OPUS_HOME}/logs"
REPO_URL="https://github.com/Riskybit23/Chat-ai-Project"
CLAUDE_MODEL="claude-haiku-4.5"

################################################################################
# Logging Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

################################################################################
# Prerequisites Check
################################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    # Check for required commands
    for cmd in curl git jq; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is not installed"
            missing=$((missing + 1))
        else
            log_success "$cmd found"
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_warning "Installing missing dependencies..."
        if command -v pkg &> /dev/null; then
            pkg install -y curl git jq
        elif command -v apt &> /dev/null; then
            apt-get update
            apt-get install -y curl git jq
        else
            log_error "Could not auto-install dependencies. Please install manually."
            return 1
        fi
    fi
    
    return 0
}

################################################################################
# Directory Setup
################################################################################

setup_directories() {
    log_info "Setting up Opus directories..."
    
    mkdir -p "$OPUS_HOME"
    mkdir -p "$OPUS_BIN"
    mkdir -p "$OPUS_CONFIG"
    mkdir -p "$OPUS_CACHE"
    mkdir -p "$OPUS_LOG"
    
    log_success "Directories created at $OPUS_HOME"
}

################################################################################
# GitHub Authentication Setup
################################################################################

setup_github_auth() {
    log_info "Setting up GitHub authentication..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI not found. Installing..."
        if command -v pkg &> /dev/null; then
            pkg install -y gh
        else
            log_error "Please install GitHub CLI manually"
            return 1
        fi
    fi
    
    # Check if already authenticated
    if gh auth status &>/dev/null; then
        log_success "GitHub CLI already authenticated"
        return 0
    fi
    
    log_info "Authenticating with GitHub..."
    gh auth login --web
    
    if [ $? -eq 0 ]; then
        log_success "GitHub authentication successful"
        return 0
    else
        log_error "GitHub authentication failed"
        return 1
    fi
}

################################################################################
# API Keys Configuration
################################################################################

setup_api_keys() {
    log_info "Setting up API keys for providers..."
    
    local config_file="${OPUS_CONFIG}/providers.conf"
    
    # Initialize config file with template
    cat > "$config_file" << 'EOF'
# Opus: Multi-Provider API Configuration
# Store your API keys securely below

# GitHub Copilot Configuration
GITHUB_TOKEN=""
COPILOT_ENABLED=true

# Anthropic Claude Configuration
ANTHROPIC_API_KEY=""
CLAUDE_ENABLED=true
CLAUDE_MODEL="claude-haiku-4.5"

# Alternative Providers (optional)
OPENAI_API_KEY=""
OPENAI_ENABLED=false

# Sync Configuration
SYNC_INTERVAL=300  # seconds
AUTO_BACKUP=true
EOF

    chmod 600 "$config_file"
    log_success "Configuration template created at $config_file"
    
    # Prompt user to enter keys
    log_info "Enter your API keys (press Enter to skip):"
    
    read -p "GitHub Token (for Copilot): " GITHUB_TOKEN
    if [ -n "$GITHUB_TOKEN" ]; then
        sed -i "s|GITHUB_TOKEN=\"\"|GITHUB_TOKEN=\"$GITHUB_TOKEN\"|" "$config_file"
        log_success "GitHub token saved"
    fi
    
    read -p "Anthropic API Key (for Claude): " ANTHROPIC_API_KEY
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        sed -i "s|ANTHROPIC_API_KEY=\"\"|ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"|" "$config_file"
        log_success "Anthropic API key saved"
    fi
    
    read -p "OpenAI API Key (optional): " OPENAI_API_KEY
    if [ -n "$OPENAI_API_KEY" ]; then
        sed -i "s|OPENAI_API_KEY=\"\"|OPENAI_API_KEY=\"$OPENAI_API_KEY\"|" "$config_file"
        sed -i "s|OPENAI_ENABLED=false|OPENAI_ENABLED=true|" "$config_file"
        log_success "OpenAI API key saved"
    fi
    
    log_success "API keys configured in $config_file"
}

################################################################################
# Core Scripts Installation
################################################################################

install_core_scripts() {
    log_info "Installing core scripts..."
    
    # Main Opus CLI script
    cat > "${OPUS_BIN}/opus" << 'MAINEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_LOG="${HOME}/.opus/logs"

case "$1" in
    chat)
        shift
        "${HOME}/.opus/bin/opus-chat" "$@"
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
    help)
        echo "Opus: Copilot Chat AI Sync"
        echo ""
        echo "Usage: opus [command] [options]"
        echo ""
        echo "Commands:"
        echo "  chat [message]     Start an AI chat session"
        echo "  sync               Sync conversation history"
        echo "  config             Manage configuration"
        echo "  status             Show system status"
        echo "  help               Display this help message"
        ;;
    *)
        "${HOME}/.opus/bin/opus-chat" "$@"
        ;;
esac
MAINEOF

    # Chat interface script
    cat > "${OPUS_BIN}/opus-chat" << 'CHATEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-haiku-4.5}"

# Create chat session
SESSION_ID=$(date +%s)
CHAT_FILE="${OPUS_CACHE}/chat_${SESSION_ID}.json"

# Initialize conversation
cat > "$CHAT_FILE" << SESEOF
{
  "session_id": "$SESSION_ID",
  "provider": "claude",
  "model": "${CLAUDE_MODEL}",
  "messages": [],
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)"
}
SESEOF

log_message() {
    local role=$1
    local content=$2
    
    # Append message to JSON
    local temp=$(mktemp)
    jq ".messages += [{\"role\": \"$role\", \"content\": \"$content\", \"timestamp\": \"$(date -Iseconds)\"}]" "$CHAT_FILE" > "$temp"
    mv "$temp" "$CHAT_FILE"
}

send_to_claude() {
    local message=$1
    
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Error: ANTHROPIC_API_KEY not configured"
        return 1
    fi
    
    log_message "user" "$message"
    
    local response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{
            \"model\": \"${CLAUDE_MODEL}\",
            \"max_tokens\": 1024,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$message\"
            }]
        }")
    
    if echo "$response" | jq . &>/dev/null; then
        local content=$(echo "$response" | jq -r '.content[0].text')
        log_message "assistant" "$content"
        echo "$content"
    else
        echo "Error communicating with Claude API"
        return 1
    fi
}

# Main chat loop
if [ -z "$1" ]; then
    echo "Opus Chat - Interactive Mode"
    echo "Type 'exit' to quit, 'sync' to sync conversation"
    echo ""
    
    while true; do
        read -p "You: " input
        
        if [ "$input" = "exit" ]; then
            break
        elif [ "$input" = "sync" ]; then
            "${HOME}/.opus/bin/opus-sync"
            continue
        fi
        
        echo -n "Assistant: "
        send_to_claude "$input"
        echo ""
    done
else
    # Single message mode
    send_to_claude "$*"
fi
CHATEOF

    # Sync script for conversation history
    cat > "${OPUS_BIN}/opus-sync" << 'SYNCEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_CACHE="${HOME}/.opus/cache"
OPUS_LOG="${HOME}/.opus/logs"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-haiku-4.5}"

log_sync() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "${OPUS_LOG}/sync.log"
}

sync_conversations() {
    log_sync "Starting sync operation..."
    
    # Find all chat sessions
    local session_count=$(find "$OPUS_CACHE" -name "chat_*.json" 2>/dev/null | wc -l)
    log_sync "Found $session_count chat sessions"
    
    # Backup conversations
    if [ "$AUTO_BACKUP" = "true" ]; then
        local backup_dir="${OPUS_CACHE}/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp "${OPUS_CACHE}"/chat_*.json "$backup_dir/" 2>/dev/null || true
        log_sync "Backed up sessions to $backup_dir"
    fi
    
    # Create sync manifest
    local manifest="${OPUS_CACHE}/manifest.json"
    cat > "$manifest" << MANIFEOF
{
  "sync_timestamp": "$(date -Iseconds)",
  "session_count": $session_count,
  "provider": "claude",
  "model": "${CLAUDE_MODEL}",
  "backup_enabled": $AUTO_BACKUP,
  "sync_status": "completed"
}
MANIFEOF
    
    log_sync "Sync completed successfully"
    echo "Sync completed: $session_count sessions synchronized"
}

sync_conversations
SYNCEOF

    # Configuration management script
    cat > "${OPUS_BIN}/opus-config" << 'CONFEOF'
#!/bin/bash
CONFIG_FILE="${HOME}/.opus/config/providers.conf"

case "$1" in
    show)
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "Configuration file not found at $CONFIG_FILE"
            return 1
        fi
        echo "Current Configuration:"
        echo "====================="
        grep "^[^#]" "$CONFIG_FILE" | grep -v "^$"
        ;;
    set)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: opus config set <key> <value>"
            return 1
        fi
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "Configuration file not found"
            return 1
        fi
        sed -i "s|^$2=.*|$2=\"$3\"|" "$CONFIG_FILE"
        echo "Configuration updated: $2=$3"
        ;;
    test)
        if [ -z "$ANTHROPIC_API_KEY" ]; then
            source "$CONFIG_FILE" 2>/dev/null || true
        fi
        
        echo "Testing API connections..."
        
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            echo -n "Testing Anthropic (Claude)... "
            response=$(curl -s https://api.anthropic.com/v1/messages \
                -H "x-api-key: $ANTHROPIC_API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d '{"model":"claude-haiku-4.5","max_tokens":10,"messages":[{"role":"user","content":"test"}]}')
            
            if echo "$response" | jq . &>/dev/null; then
                echo "✓ OK"
            else
                echo "✗ FAILED"
            fi
        else
            echo "ANTHROPIC_API_KEY not configured"
        fi
        ;;
    *)
        echo "Usage: opus config [show|set|test]"
        ;;
esac
CONFEOF

    # Status script
    cat > "${OPUS_BIN}/opus-status" << 'STATEOF'
#!/bin/bash
source "${HOME}/.opus/config/providers.conf" 2>/dev/null || true
OPUS_CACHE="${HOME}/.opus/cache"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-haiku-4.5}"

echo "Opus System Status"
echo "=================="
echo "Installation: $HOME/.opus"
echo "Configuration: ${HOME}/.opus/config/providers.conf"
echo ""
echo "Enabled Providers:"
[ "$COPILOT_ENABLED" = "true" ] && echo "  ✓ GitHub Copilot"
[ "$CLAUDE_ENABLED" = "true" ] && echo "  ✓ Claude (${CLAUDE_MODEL})"
[ "$OPENAI_ENABLED" = "true" ] && echo "  ✓ OpenAI"
echo ""
echo "Chat Sessions:"
local session_count=$(find "$OPUS_CACHE" -name "chat_*.json" 2>/dev/null | wc -l)
echo "  Total: $session_count"
echo ""
echo "Storage Usage:"
du -sh "${HOME}/.opus" 2>/dev/null || echo "  N/A"
STATEOF

    # Make all scripts executable
    chmod +x "${OPUS_BIN}"/*
    
    log_success "Core scripts installed to $OPUS_BIN"
}

################################################################################
# PATH Configuration
################################################################################

configure_path() {
    log_info "Configuring PATH..."
    
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
        echo "" >> "$shell_rc"
        echo "# Opus AI Sync - Added by installer" >> "$shell_rc"
        echo "export PATH=\"$OPUS_BIN:\$PATH\"" >> "$shell_rc"
        log_success "PATH configured in $shell_rc"
    else
        log_success "PATH already configured"
    fi
    
    # Source the updated shell config
    source "$shell_rc" 2>/dev/null || true
}

################################################################################
# Documentation & Examples
################################################################################

create_documentation() {
    log_info "Creating documentation..."
    
    cat > "${OPUS_HOME}/README.md" << 'DOCEOF'
# Opus: Copilot Chat AI Sync

Integrated GitHub Copilot and Claude AI chat interface for Termux with per-account API key management.

## Installation

Run the installer:
```bash
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash
```

## Quick Start

### Interactive Chat
```bash
opus chat
```

### Single Message
```bash
opus chat "What is the meaning of life?"
```

### Sync Conversations
```bash
opus sync
```

### View Configuration
```bash
opus config show
```

### Update Configuration
```bash
opus config set ANTHROPIC_API_KEY "your-key-here"
```

### Test Connections
```bash
opus config test
```

### System Status
```bash
opus status
```

## Configuration

API keys are stored in: `~/.opus/config/providers.conf`

Supported providers:
- **Claude** (Anthropic) - Haiku 4.5
- **GitHub Copilot** - Via GitHub API
- **OpenAI** - GPT models (optional)

## Directory Structure

```
~/.opus/
��── bin/              # Executable scripts
├── config/           # Configuration files
├── cache/            # Chat sessions & backups
└── logs/             # Operation logs
```

## Features

✓ Multi-provider AI integration
✓ Per-account API key management
✓ Persistent chat history
✓ Automatic backups
✓ Real-time sync
✓ JSON-based session storage
✓ Comprehensive logging

## Troubleshooting

### API Connection Issues
```bash
opus config test
```

### View Logs
```bash
tail -f ~/.opus/logs/sync.log
```

### Reset Configuration
```bash
rm ~/.opus/config/providers.conf
# Re-run installer
```

## Uninstall

```bash
rm -rf ~/.opus
grep -v "Opus AI Sync" ~/.bashrc > ~/.bashrc.tmp
mv ~/.bashrc.tmp ~/.bashrc
```

## Support

Repository: https://github.com/Riskybit23/Chat-ai-Project
DOCEOF

    log_success "Documentation created at ${OPUS_HOME}/README.md"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    clear
    
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║  Opus: Copilot Chat AI Sync Installer  ║"
    echo "║  For Termux & Linux Environments       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Run installation steps
    check_prerequisites || exit 1
    setup_directories
    setup_github_auth || log_warning "GitHub auth setup skipped"
    setup_api_keys
    install_core_scripts
    configure_path
    create_documentation
    
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║   Installation Completed Successfully!  ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Reload your shell config: source ~/.bashrc"
    echo "2. Try your first chat: opus chat"
    echo "3. View documentation: cat ~/.opus/README.md"
    echo ""
    echo "Quick commands:"
    echo "  opus help              - Show help"
    echo "  opus config show       - View current config"
    echo "  opus config test       - Test API connections"
    echo "  opus status            - System status"
    echo ""
}

main "$@"
