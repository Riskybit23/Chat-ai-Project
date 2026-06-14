# Opus: GitHub Copilot Chat AI Sync

> A simplified, secure chat interface for GitHub Copilot with per-account and per-device isolation.

**Version:** 1.1.0  
**Focus:** GitHub Copilot Only (Simplified & Optimized)  
**Status:** ✅ Production Ready

---

## 🎯 Features

✅ **GitHub Copilot Integration**
- Direct API integration with GitHub Copilot
- Real-time chat responses
- Session-based conversations

✅ **Per-Account Isolation**
- Unique account ID for each user
- Account-specific session storage
- Separate history per account

✅ **Per-Device Isolation**
- Unique device ID generation
- Device-specific token management
- Track device information

✅ **Secure Token Storage**
- GitHub token stored locally with 600 permissions (owner-only)
- Token metadata tracking
- Token rotation support

✅ **Session Management**
- Automatic session tracking
- JSON-based session storage
- Full chat history preservation

✅ **Chat History Search**
- Full-text search across all sessions
- Quick retrieval of past conversations
- Context-aware results

✅ **Code Snippets Manager**
- Save frequently used code snippets
- Quick add/list/get operations
- Language-specific storage

✅ **Automatic Backups**
- Daily automatic backups
- Timestamped backup directories
- Simple recovery mechanism

---

## 📋 Requirements

- **OS:** Termux, Linux, macOS
- **Shell:** Bash, Zsh, or Fish
- **Tools:** curl, git, jq
- **GitHub:** Account with Copilot access
- **Storage:** ~100MB

---

## 🚀 Quick Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash
```

### After Installation

```bash
# Reload shell
source ~/.bashrc

# Verify installation
opus status

# Test GitHub Copilot connection
opus config test

# Start chatting
opus chat "Hello Copilot!"
```

---

## 📖 Usage

### Interactive Chat

```bash
opus chat
# Then type your messages interactively
```

### Single Message

```bash
opus chat "Explain quantum computing"
opus chat "Fix this bug: [code]"
```

### Search Chat History

```bash
opus search "python"
opus search "async await"
```

### Manage Code Snippets

```bash
# List all snippets
opus snippets list

# Add new snippet
opus snippets add my_template
# [paste your code, Ctrl+D when done]

# Get snippet
opus snippets get my_template

# Delete snippet
opus snippets del my_template
```

### Sync & Backup

```bash
# Backup current sessions
opus sync

# Check system status
opus status
```

### Configuration Management

```bash
# View configuration
opus config status

# Test connection
opus config test

# Rotate token (for security)
opus config rotate-token

# Clear device ID (reset device)
opus config clear-device

# Clear account ID (switch account)
opus config clear-account
```

---

## 🏗️ Directory Structure

```
~/.opus/
├── bin/                    # Executable scripts
│   ├── opus               # Main CLI
│   ├── opus-chat          # Chat interface
│   ├── opus-search        # History search
│   ├── opus-snippets      # Snippet manager
│   ├── opus-sync          # Sync utility
��   ├── opus-config        # Config manager
│   └── opus-status        # Status viewer
├── config/
│   ├── copilot_token      # GitHub token (600 permissions)
│   ├── token_info         # Token metadata
│   ├── .device_id         # Device identifier
│   └── .account_id        # Account identifier
├── cache/
│   ├── sessions/          # Chat sessions (JSON)
│   └── backups/           # Timestamped backups
├── data/
│   └── snippets/          # Saved code snippets
└── logs/                  # Operation logs
```

---

## 🔒 Security

### Token Protection
- GitHub token stored with `600` permissions (owner-only read/write)
- Token never logged or displayed
- Secure temporary file handling

### Per-Account Isolation
```bash
Account ID: github_username_1718361234
```
- Unique per GitHub account
- Tracks account changes
- Separate session storage

### Per-Device Isolation
```bash
Device ID: a7f3d2e1b4c6f9a8
```
- Auto-generated on first run
- Persists across sessions
- Enables multi-device usage

### Session Security
- Session IDs use nanosecond precision
- Metadata includes OS, hostname, user
- Automatic backup verification

---

## 🔄 Workflow Example

```bash
# 1. Start interactive session
opus chat

# 2. Ask Copilot questions
You: Create a Python function to sort a list
Copilot: def sort_list(items):
         return sorted(items)

# 3. Save useful snippets
opus snippets add python_sort

# 4. Later, retrieve snippet
opus snippets get python_sort

# 5. Search past conversations
opus search "sorting"

# 6. Backup everything
opus sync
```

---

## 📊 Account & Device Management

### View Current Setup

```bash
opus status
```

Output:
```
Device & Account Isolation:
  Device ID: a7f3d2e1b4c6f9a8
  Account ID: github_username_1718361234

Chat Statistics:
  Total Sessions: 42
  Backups: 3
```

### Switch GitHub Account

```bash
# Clear current account
opus config clear-account

# Logout and login with new account
gh auth logout
gh auth login

# Re-run installer or setup
# New account ID will be generated
```

### Use on New Device

```bash
# Install and run
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash

# New device ID auto-generated
# Token setup via GitHub auth
# Completely isolated from other devices
```

---

## ⚙️ Configuration

Edit token info file:

```bash
cat ~/.opus/config/token_info
```

Example output:
```json
{
  "device_id": "a7f3d2e1b4c6f9a8",
  "account_id": "github_username_1718361234",
  "created_at": "2026-06-14T19:43:58Z",
  "last_used": "2026-06-14T20:15:30Z",
  "os": "linux-android",
  "hostname": "localhost",
  "user": "riskybit23"
}
```

---

## 🐛 Troubleshooting

### Token Issues

```bash
# Test connection
opus config test

# Rotate token if expired
opus config rotate-token
```

### Account Problems

```bash
# Clear account and setup new one
opus config clear-account

# Re-run installer
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash
```

### Device Issues

```bash
# Reset device
opus config clear-device

# Generate new device ID
rm ~/.opus/config/.device_id
opus status
```

### GitHub Authentication

```bash
# Check auth status
gh auth status

# Re-authenticate
gh auth logout
gh auth login --web
```

---

## 📚 Commands Reference

| Command | Purpose |
|---------|----------|
| `opus chat` | Interactive mode |
| `opus chat "msg"` | Send single message |
| `opus search "term"` | Search history |
| `opus snippets list` | List snippets |
| `opus snippets add <name>` | Add snippet |
| `opus snippets get <name>` | Retrieve snippet |
| `opus snippets del <name>` | Delete snippet |
| `opus sync` | Backup sessions |
| `opus status` | Show system info |
| `opus config status` | View configuration |
| `opus config test` | Test Copilot |
| `opus config rotate-token` | Rotate token |
| `opus config clear-device` | Reset device |
| `opus config clear-account` | Switch account |
| `opus help` | Show help |

---

## 🔄 Upgrade Path

If upgrading from v1.0:

```bash
# Backup old installation
cp -r ~/.opus ~/.opus-backup

# Re-run installer
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash

# Verify
opus status
```

---

## ❓ FAQ

**Q: Can I use Opus on multiple devices?**

A: Yes! Each device gets a unique Device ID. Account ID ensures your conversations are tied to your GitHub account.

**Q: Is my token secure?**

A: Yes. Tokens are stored with 600 permissions (owner-only). They're never logged or displayed.

**Q: Can I share my installation across accounts?**

A: Not recommended. Each account should have its own installation for proper isolation.

**Q: How do I backup everything?**

A: Run `opus sync` or simply backup the `~/.opus` directory.

**Q: Can I use this offline?**

A: No. Opus requires internet access to connect to GitHub Copilot API.

---

## 🤝 Contributing

Fork and submit PRs at: https://github.com/Riskybit23/Chat-ai-Project

---

## 📄 License

Apache License 2.0 - See LICENSE file

---

## 🔗 Links

- 🏠 [GitHub Repository](https://github.com/Riskybit23/Chat-ai-Project)
- 📝 [GitHub Copilot Docs](https://docs.github.com/en/copilot)
- 🐛 [Report Issues](https://github.com/Riskybit23/Chat-ai-Project/issues)
- 💬 [Discussions](https://github.com/Riskybit23/Chat-ai-Project/discussions)

---

**Made with ❤️ by Riskybit23**

*Last Updated: June 2026*
