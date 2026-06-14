# Opus Version History

## v1.1.0 (Current - June 14, 2026)

### 🎯 Focus: GitHub Copilot Only

**Breaking Changes:**
- Removed Claude support
- Removed OpenAI support  
- Removed Google Gemini support
- Removed multi-provider switching

**Improvements:**
- ✅ Fixed GitHub authentication flow
- ✅ Improved token management
- ✅ Per-account isolation implementation
- ✅ Per-device isolation implementation
- ✅ Better error handling
- ✅ Cleaner configuration
- ✅ Improved documentation

**Features Added:**
- Device ID auto-generation
- Account ID tracking
- Token metadata storage
- Token rotation mechanism
- Device/account management commands

**Bug Fixes:**
- Fixed shell detection issues
- Fixed directory permissions
- Fixed PATH configuration
- Fixed token handling
- Fixed session tracking

**File Changes:**
- Simplified installer script
- Removed multi-provider logic
- Added device/account isolation
- Improved error messages
- Better documentation

---

## v1.0.0 (Previous - June 14, 2026)

### Initial Release with Multiple Providers

**Supported Providers:**
- Claude (Anthropic)
- OpenAI (GPT-4/3.5)
- Google Gemini
- GitHub Copilot

**Issues (Fixed in v1.1.0):**
- ❌ Complex multi-provider logic
- ❌ Unclear account/device isolation
- ❌ Token management issues
- ❌ Authentication problems
- ❌ Error handling gaps

---

## Migration Guide: v1.0 → v1.1.0

### Backup First

```bash
cp -r ~/.opus ~/.opus-v1-backup
```

### Clean Install

```bash
rm -rf ~/.opus
curl -fsSL https://raw.githubusercontent.com/Riskybit23/Chat-ai-Project/main/install-termux.sh | bash
```

### Changes

| Aspect | v1.0 | v1.1.0 |
|--------|------|--------|
| Providers | 4 | 1 (GitHub Copilot) |
| Config | Complex | Simple |
| Isolation | None | Per-device, Per-account |
| Token Mgmt | Basic | Advanced |
| Error Handling | Poor | Robust |

### Data Loss

⚠️ **v1.1.0 is not backward compatible**

Old chat sessions will not be imported due to provider changes. Backup if needed:

```bash
cp -r ~/.opus-v1-backup/cache/sessions ~/.opus-v1-sessions
```

---

## Future Versions

### v1.2.0 (Planned)
- [ ] Cloud synchronization
- [ ] Advanced search (date range, regex)
- [ ] Conversation branching
- [ ] Custom prompt templates
- [ ] Enhanced logging

### v2.0.0 (Planned)
- [ ] Web UI
- [ ] Mobile app
- [ ] Team collaboration
- [ ] Real-time streaming
- [ ] Plugin system

---

**Current Version: 1.1.0**

**Release Date: June 14, 2026**

**Status: Stable & Production Ready ✓**
