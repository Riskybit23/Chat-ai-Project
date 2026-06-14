# Opus v2: Complete Feature Documentation

## 🎯 Core Features

### 1. Multi-Provider AI Integration

#### Claude (Anthropic) - Recommended
- **Models:** claude-3-5-sonnet, claude-3-opus, claude-3-haiku
- **Strengths:** Best for reasoning, coding, analysis
- **Cost:** Mid-range
- **Speed:** Fast
- **Configuration:**
  ```bash
  opus config set ANTHROPIC_API_KEY "sk-ant-..."
  opus config set CLAUDE_MODEL "claude-3-5-sonnet-20241022"
  ```

#### OpenAI (GPT Models)
- **Models:** gpt-4-turbo, gpt-4, gpt-3.5-turbo
- **Strengths:** Latest capabilities, great for creative tasks
- **Cost:** Higher
- **Speed:** Fast
- **Configuration:**
  ```bash
  opus config set OPENAI_API_KEY "sk-..."
  opus config set OPENAI_MODEL "gpt-4-turbo"
  ```

#### Google Gemini
- **Models:** gemini-1.5-pro, gemini-pro
- **Strengths:** Excellent multimodal, long context
- **Cost:** Low
- **Speed:** Varies
- **Configuration:**
  ```bash
  opus config set GEMINI_API_KEY "..."
  opus config set GEMINI_MODEL "gemini-1.5-pro"
  ```

### 2. Chat System

#### Interactive Mode
```bash
opus chat
```
- Real-time conversation
- Message history per session
- Auto-save functionality
- Exit commands: `exit`, `quit`, `bye`

#### Single Message Mode
```bash
opus chat "Your question here"
```
- Quick queries
- Script-friendly
- Perfect for automation
- Returns JSON for parsing

#### Context-Aware Chatting
```bash
opus chat-context "Continue from last time"
```
- Remembers up to N previous messages
- Configurable context window
- Automatic context pruning
- Better for complex discussions

### 3. Session Management

#### Automatic Session Tracking
- Unique session IDs (nanosecond precision)
- Per-session metadata:
  - Timestamp
  - OS/System info
  - User info
  - Provider used
  - Model used

#### Session Storage
```
~/.opus/cache/sessions/
├── chat_1718361234567890123.json
├── chat_1718361245678901234.json
└── chat_1718361256789012345.json
```

#### Session Backup
```bash
# Automatic daily backups
~/.opus/cache/backups/
├── 20260614_093000/
├── 20260614_183000/
└── 20260615_093000/
```

### 4. Chat History Search

#### Full-Text Search
```bash
opus search "keyword"
opus search "machine learning"
opus search "deployment"
```

#### Advanced Queries
```bash
# Search in specific date range (future enhancement)
opus search --since "2026-06-01" "topic"
opus search --limit 5 "query"
```

#### Search Results
- File path to matching session
- Line number in JSON
- Context preview
- Timestamp

### 5. Code Snippets Manager

#### Add Snippets
```bash
opus snippets add python_template
# [Enter code, Ctrl+D when done]
```

#### List Snippets
```bash
opus snippets list
# Output:
# - python_template
# - bash_script
# - javascript_react
```

#### Retrieve Snippets
```bash
opus snippets get python_template
# Outputs the saved code
```

#### Use Cases
- Save frequently used code patterns
- Quick templates for different languages
- Helper functions
- Configuration templates

### 6. Voice Input Mode

#### Enable Voice
```bash
opus config set ENABLE_VOICE_INPUT true
opus voice
```

#### Features
- Speech-to-text conversion
- Text-to-speech responses (optional)
- Offline voice recognition (with additional setup)
- Multiple language support

#### Requirements
- `sox` audio processing
- Microphone access
- Optional: OfflineRASR for offline mode

### 7. Configuration Management

#### View Configuration
```bash
opus config show
```
Output:
```
═══════════════════════════════════════
Opus Configuration
═══════════════════════════════════════
ANTHROPIC_API_KEY=sk-ant-...***
CLAUDE_ENABLED=true
CLAUDE_MODEL="claude-3-5-sonnet-20241022"
OPENAI_ENABLED=false
AI_TEMPERATURE=0.7
API_TIMEOUT=30
AUTO_BACKUP=true
═══════════════════════════════════════
```

#### Set Configuration
```bash
opus config set ANTHROPIC_API_KEY "your-key"
opus config set AI_TEMPERATURE "1.2"
opus config set API_TIMEOUT "60"
```

#### Test Configuration
```bash
opus config test
```
Output:
```
Testing API connections...
  Testing Claude (Anthropic)... ✓ OK
  Testing OpenAI... ✗ FAILED
  Testing Gemini... ✓ OK
```

#### Reset Configuration
```bash
opus config reset
# Prompts for confirmation
```

### 8. System Status & Monitoring

#### View Status
```bash
opus status
```
Output:
```
╔════════════════════════════════════════╗
║  Opus System Status v2                  ║
╚════════════════════════════════════════╝

Installation: /home/user/.opus
Version: 2.0.0

Enabled Providers:
  ✓ Claude (Model: claude-3-5-sonnet-20241022)
  ✗ OpenAI (Not configured)
  ✓ Gemini (Model: gemini-1.5-pro)

Statistics:
  Chat Sessions: 42
  Backup Location: /home/user/.opus/cache/backups
  Logs Location: /home/user/.opus/logs

Storage Usage:
  Total: 2.3M

System Info:
  OS: linux-gnu
  Shell: /bin/bash
  User: riskybit23
```

### 9. Synchronization & Backup

#### Manual Sync
```bash
opus sync
```
Actions:
- Finds all chat sessions
- Creates timestamped backup
- Generates sync manifest
- Updates statistics

#### Automatic Sync
- Triggered after every chat
- Scheduled via cron (optional)
- Background service (future)

#### Backup Management
```
~/.opus/cache/backups/
├── 20260614_093000/      # 4 sessions backed up
├── 20260614_183000/      # 6 sessions backed up
└── 20260615_093000/      # 8 sessions backed up
```

### 10. Logging & Debugging

#### Log Levels
```bash
opus config set LOG_LEVEL "debug"  # Verbose
opus config set LOG_LEVEL "info"   # Normal
opus config set LOG_LEVEL "warn"   # Warnings only
opus config set LOG_LEVEL "error"  # Errors only
```

#### Enable Debug Mode
```bash
DEBUG=true opus chat
```

#### View Logs
```bash
# Recent sync operations
tail -50 ~/.opus/logs/sync.log

# Search for errors
grep "ERROR" ~/.opus/logs/*.log

# Real-time log monitoring
tail -f ~/.opus/logs/sync.log
```

---

## 🎓 Advanced Usage

### Temperature Control

Control AI creativity:

```bash
# Deterministic (0.0) - Same responses
opus config set AI_TEMPERATURE "0.0"

# Balanced (0.7) - Default
opus config set AI_TEMPERATURE "0.7"

# Creative (1.5) - More varied
opus config set AI_TEMPERATURE "1.5"

# Very Creative (2.0) - Maximum variation
opus config set AI_TEMPERATURE "2.0"
```

### Max Tokens Configuration

```bash
# Short responses
opus config set CLAUDE_MAX_TOKENS "500"

# Long responses
opus config set CLAUDE_MAX_TOKENS "4096"

# Using with OpenAI
opus config set OPENAI_MAX_TOKENS "2000"
```

### API Timeout

```bash
# Fast network
opus config set API_TIMEOUT "15"

# Slow network
opus config set API_TIMEOUT "60"

# Very slow or large responses
opus config set API_TIMEOUT "120"
```

### Context Memory

```bash
# Remember last 5 messages
opus config set CONTEXT_MEMORY_SIZE "5"

# Remember last 20 messages
opus config set CONTEXT_MEMORY_SIZE "20"

# Very long context (slower, more tokens)
opus config set CONTEXT_MEMORY_SIZE "50"
```

---

## 📊 Performance Tuning

### For Speed
```bash
opus config set CLAUDE_MODEL "claude-3-haiku-20240307"  # Fastest
opus config set CLAUDE_MAX_TOKENS "1024"
opus config set API_TIMEOUT "20"
```

### For Quality
```bash
opus config set CLAUDE_MODEL "claude-3-opus-20240229"   # Best
opus config set CLAUDE_MAX_TOKENS "4096"
opus config set API_TIMEOUT "60"
```

### For Cost
```bash
opus config set GEMINI_MODEL "gemini-1.5-pro"           # Cheapest
opus config set CLAUDE_MAX_TOKENS "1024"
```

---

## 🔐 Security Features

### Key Storage
- Config file permissions: 600 (owner-only)
- Masked display in config show
- Environment variable isolation
- No logging of sensitive data

### Session Security
- Unique session IDs
- Timestamp verification
- User context logging
- Backup integrity checks

---

## 🚀 Future Enhancements

- [ ] Plugin system
- [ ] Custom prompt templates
- [ ] Conversation branching
- [ ] Collaborative sessions
- [ ] Cloud synchronization
- [ ] Mobile app integration
- [ ] Advanced analytics
- [ ] Real-time streaming

---

**Documentation Version:** 2.0.0
**Last Updated:** June 2026
