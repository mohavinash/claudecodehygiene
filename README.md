# Claude Code Hygiene

A comprehensive collection of Claude Code hooks for maintaining clean, consistent, and well-documented codebases. These hooks automatically format code, enforce documentation standards, and maintain consistent comment styles.

> Inspired by [iannuttall/claude-sessions](https://github.com/iannuttall/claude-sessions) - extending the concept to code quality automation.

## 📚 Documentation

- **Official Hooks Documentation**: [Claude Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks)
- Learn more about how hooks work and how to create your own custom hooks

## 🚀 Features

- **Automatic Code Formatting**: Prettier and ESLint integration on file changes
- **JSDoc Enforcement**: Blocks undocumented exports and adds templates
- **Comment Standardization**: Converts TODO/HACK comments to consistent format
- **Code Organization**: Adds section separators for better readability
- **Validation Hooks**: Pre-commit style checks before modifications

## 📦 Installation

1. Locate your Claude Code settings file:
   ```bash
   # Project-specific settings
   .claude/settings.local.json
   
   # Or global settings
   ~/.config/claude/settings.json
   ```

2. Add the hooks from this repository to your settings file (see examples below)

3. Ensure you have the required tools installed:
   ```bash
   npm install -g prettier eslint
   # or locally in your project
   npm install --save-dev prettier eslint
   ```

## 🔧 Available Hooks

### 1. Auto-Formatting Hook
Automatically runs Prettier and ESLint on JavaScript/TypeScript files after edits.

```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.html|*.vue|*.md) command -v prettier >/dev/null && prettier --write \"$file\" 2>/dev/null; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) command -v eslint >/dev/null && eslint --fix \"$file\" 2>/dev/null;; esac;; esac; done; echo \"Formatting complete\""
  }]
}
```

### 2. JSDoc Template Generator
Adds JSDoc templates to undocumented exported functions.

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) if grep -E '(export\\s+(function|const\\s+\\w+\\s*=.*=>|class)|^(function|const\\s+\\w+\\s*=.*=>)\\s+\\w+)' \"$file\" >/dev/null 2>&1; then temp_file=$(mktemp); awk '/export\\s+(function|const\\s+\\w+\\s*=.*=>|class)|^(function|const\\s+\\w+\\s*=.*=>)\\s+\\w+/ { if (prev !~ /^\\s*\\/\\*\\*/) { print \"/**\"; print \" * PURPOSE: [What this does in one clear sentence]\"; print \" * INPUTS: [Parameters/props - be specific about types]\"; print \" * OUTPUTS: [What it returns/renders]\"; print \" * EDGE_CASES: [Error states, empty data, loading states]\"; print \" */\"; } } { prev = $0; print }' \"$file\" > \"$temp_file\" && mv \"$temp_file\" \"$file\"; echo \"📝 Added JSDoc templates to $file\"; fi;; esac; done"
  }]
}
```

### 3. Comment Standardization
Converts various comment styles to a consistent format.

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) temp_file=$(mktemp); sed -E 's|//\\s*TODO:.*|// TODO moved to issue tracker|g; s|//\\s*HACK:.*|// Refactoring needed - see issue tracker|g; s|//\\s*NOTE:\\s*(.*)$|// \\1|g; s|//:\\s*PURPOSE:\\s*(.*)$|// \\1|g; s|/\\*\\*\\s*([^*].*)\\s*\\*/|// \\1|g' \"$file\" > \"$temp_file\" && mv \"$temp_file\" \"$file\"; echo \"🔧 Standardized comments in $file\";; esac; done"
  }]
}
```

### 4. Code Section Organizer
Adds section separators to files over 50 lines for better organization.

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) line_count=$(wc -l < \"$file\"); if [ \"$line_count\" -gt 50 ]; then temp_file=$(mktemp); awk '/^(import|const.*=.*require)/ && imports_done == 0 { print; if (getline line == 0) imports_done = 1; else { print line; if (line !~ /^(import|const.*=.*require)/) { print \"\"; print \"/* ===== Main Implementation ===== */\"; print \"\"; imports_done = 1; } } next } /^export/ && exports_started == 0 { print \"\"; print \"/* ===== Exports ===== */\"; print \"\"; exports_started = 1 } { print }' \"$file\" > \"$temp_file\" && mv \"$temp_file\" \"$file\"; echo \"📋 Added section separators to $file\"; fi;; esac; done"
  }]
}
```

### 5. Pre-Edit Validation Hooks

#### Comment Style Validator
Warns about non-standard comment styles before editing.

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); violations=\"\"; echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) if grep -E '//\\s*TODO:|//\\s*HACK:|//\\s*NOTE:|//:\\s*PURPOSE:' \"$file\" >/dev/null 2>&1; then violations=\"$violations\\n❌ $file: Found non-standard comment styles\"; fi; if grep -E 'const\\s+\\w+\\s*=\\s*\\w+\\.\\w+;\\s*//.*Set.*|return\\s+\\w+;\\s*//.*Return.*|\\.forEach\\s*\\(\\s*\\w+\\s*=>\\s*.*//.*Loop.*' \"$file\" >/dev/null 2>&1; then violations=\"$violations\\n❌ $file: Found obvious comments that should be removed\"; fi;; esac; done; if [ -n \"$violations\" ]; then printf \"\\n🚨 Comment Standards Violations:%s\\n\\nPlease fix these issues:\\n- Use /** */ for documentation blocks\\n- Use // for inline explanations only\\n- Use /* ===== */ for section separators\\n- Remove obvious comments\\n\" \"$violations\" >&2; fi"
  }]
}
```

#### JSDoc Enforcement
Blocks edits to files with undocumented exports.

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "input=$(cat); tool_name=$(echo \"$input\" | jq -r '.tool_name // empty' 2>/dev/null); if [ \"$tool_name\" = \"Write\" ] || [ \"$tool_name\" = \"Edit\" ] || [ \"$tool_name\" = \"MultiEdit\" ]; then files=$(echo \"$input\" | jq -r 'if .tool_input.path then .tool_input.path elif .tool_input.paths then .tool_input.paths[] elif .tool_input.files then .tool_input.files[].path else empty end' 2>/dev/null); missing_docs=\"\"; echo \"$files\" | while read -r file; do [ -f \"$file\" ] || continue; case \"$file\" in *.js|*.jsx|*.ts|*.tsx) exports=$(grep -n -E '^export\\s+(function|const\\s+\\w+\\s*=|class)' \"$file\" 2>/dev/null); echo \"$exports\" | while IFS=: read -r line_num line_content; do [ -n \"$line_num\" ] || continue; prev_lines=$(sed -n \"$((line_num-5)),$((line_num-1))p\" \"$file\" 2>/dev/null); if ! echo \"$prev_lines\" | grep -q '/\\*\\*.*PURPOSE:'; then missing_docs=\"$missing_docs\\n❌ $file:$line_num: Missing JSDoc for exported function/component\"; fi; done;; esac; done; if [ -n \"$missing_docs\" ]; then printf \"\\n📚 Missing Documentation:%s\\n\\nPlease add JSDoc blocks with PURPOSE, INPUTS, OUTPUTS, and EDGE_CASES sections.\\n\" \"$missing_docs\" >&2; echo '{\"decision\": \"block\", \"reason\": \"Missing required JSDoc documentation for exported functions/components. Please add documentation blocks before proceeding.\"}'; fi; fi"
  }]
}
```

## 📝 Complete Example Configuration

See [examples/settings.local.json](examples/settings.local.json) for a complete configuration file with all hooks.

## 🎨 Customization Guide

### Adapting for Different Comment Styles

To customize the JSDoc template format:
```bash
# Change the template in the awk script
print "/**";
print " * @description TODO";
print " * @param {*} param - Description";
print " * @returns {*} Description";
print " */";
```

### Adding Support for Other Languages

Extend the file matching pattern:
```bash
case "$file" in 
  *.js|*.jsx|*.ts|*.tsx|*.py|*.rb|*.go)
    # Your logic here
  ;;
esac
```

### Customizing Formatting Tools

Replace prettier/eslint with your preferred tools:
```bash
# For Python
command -v black >/dev/null && black "$file" 2>/dev/null

# For Go
command -v gofmt >/dev/null && gofmt -w "$file" 2>/dev/null
```

## 🛠️ Troubleshooting

### Hook Not Triggering
1. Check that the hook is in the correct section (PreToolUse vs PostToolUse)
2. Verify the matcher pattern matches your tool usage
3. Ensure required tools (prettier, eslint) are installed

### Syntax Errors
1. Each hook command must be a single line
2. Avoid literal newline characters (`\n`) in the middle of commands
3. Ensure all `case` statements end with `;;` before `esac`

### Permission Errors
Add required permissions to your settings:
```json
"permissions": {
  "allow": [
    "Bash(command:*)",
    "Bash(prettier:*)",
    "Bash(eslint:*)",
    "Bash(sed:*)",
    "Bash(awk:*)",
    "Bash(grep:*)"
  ]
}
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request with:
- New hook types
- Language-specific adaptations
- Performance improvements
- Bug fixes

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ian Nuttall](https://github.com/iannuttall) for the inspiration with claude-sessions
- The Claude Code team for making extensible AI coding possible
- The open source community for tools like Prettier and ESLint

---

Made with ❤️ for the Claude Code community