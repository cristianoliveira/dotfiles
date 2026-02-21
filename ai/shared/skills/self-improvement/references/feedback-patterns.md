# Feedback Patterns by Agent Type

This guide documents common mistake patterns, their causes, and recommended corrections for different agent types.

## File Operations Agent

### Pattern 1: Edit Without Reading First
**Mistake:** Use `edit` tool on file without first reading it
**Cause:** Assumption about file structure; trying to be fast
**Correction:** ALWAYS use `read` tool first (use `limit` param if file is large)
**Severity:** HIGH
**Tags:** file-ops, safety, sequence, missing-validation
**Prevention Rules:**
- If unsure about file contents → read with `limit` first
- If file is very large (>5000 lines) → use `limit` parameter
- Use `glob` to verify file paths before operations

**Verification:** Before edit, always confirm file structure with read

---

### Pattern 2: Overwrite Without Backup Check
**Mistake:** Use `write` tool to overwrite file without checking if existing content matters
**Cause:** Didn't read existing file; assumed it's safe to replace
**Correction:** Always read existing file first; if overwriting, ensure you understand what's lost
**Severity:** HIGH
**Tags:** file-ops, safety, data-loss, missing-validation

**Verification Steps:**
1. Read file to understand current content
2. If not creating new file, note what will be lost
3. Confirm with user if overwriting important content
4. Use version control (git) to track changes

---

### Pattern 3: Path Assumptions Across Platforms
**Mistake:** Use hardcoded paths like `/home/user/...` without considering macOS vs Linux
**Cause:** Assumption about OS; didn't verify environment
**Correction:** Use environment variables (`$HOME`, `$PWD`) or ask user for absolute paths
**Severity:** MEDIUM
**Tags:** file-ops, cross-platform, assumptions
**Examples:**
- ❌ `/home/user/.config/...` → ✅ `$HOME/.config/...`
- ❌ `/opt/app` → ✅ Ask user: "Where is the app installed?"

---

## Git Operations Agent

### Pattern 1: Push Without Branch Status Check
**Mistake:** Attempt push without verifying branch is tracking remote and is clean
**Cause:** Skipped `git status` and `git fetch` step
**Correction:** Always run `git status` and `git fetch` before any push
**Severity:** HIGH
**Tags:** git, safety, sequence-mistake, branch-tracking

**Sequence Rule:**
```
1. git status                    # Verify branch is clean
2. git fetch origin             # Get latest remote state
3. git status                    # Verify no conflicts
4. git push (with -u if new)   # Only after verifying above
```

---

### Pattern 2: Force Push to Protected Branches
**Mistake:** Use `git push --force` on main/master without explicit user approval
**Cause:** Didn't read git safety guidelines; tried to "fix" fast
**Correction:** NEVER force push to main/master. Force push only to personal branches with explicit permission.
**Severity:** CRITICAL
**Tags:** git, safety, destructive, permissions
**Guardian Rules:**
- Block ALL `git push --force` to main/master
- Warn if attempting force push to ANY protected branch
- Require explicit user confirmation for force push anywhere

---

### Pattern 3: Amend Without Verifying Commit
**Mistake:** Use `git commit --amend` when it's unsafe (already pushed, previous commit by user)
**Cause:** Didn't verify: was this commit created by me? Was it pushed?
**Correction:** Before amend, verify: `git log -1 --format='%an %ae'` and `git status` (check "Your branch is ahead")
**Severity:** MEDIUM
**Tags:** git, safety, assumptions, commit-history

**Safe Amend Checklist:**
- [ ] Latest commit created by this agent (check `git log`)
- [ ] Commit has NOT been pushed (check `git status` for "ahead of")
- [ ] User explicitly requested amend
- [ ] OR pre-commit hook auto-modified files that need including

---

## Bash Execution Agent

### Pattern 1: Command Not Found / Missing Tools
**Mistake:** Run command without checking if tool exists in environment
**Cause:** Assumed tool is installed; didn't verify with `which` or test
**Correction:** Test command with `command -v <tool>` before using. Provide fallback or ask user if missing.
**Severity:** MEDIUM
**Tags:** bash, tool-missing, assumptions

**Verification:**
```bash
command -v npm > /dev/null || { echo "npm not found"; exit 1; }
```

---

### Pattern 2: Wildcard Expansion Issues
**Mistake:** Use glob patterns without proper quoting; patterns expand when shouldn't
**Cause:** Didn't quote glob patterns; forgot about shell expansion
**Correction:** Always quote glob patterns: `"**/*.js"` not `**/*.js`
**Severity:** MEDIUM
**Tags:** bash, quoting, patterns, arguments

---

### Pattern 3: Timeout and Long-Running Commands
**Mistake:** Run command that takes longer than default timeout without setting timeout param
**Cause:** Didn't provide `timeout` parameter in bash tool
**Correction:** For potentially long commands (tests, builds), set appropriate timeout (in milliseconds)
**Severity:** MEDIUM
**Tags:** bash, timeout, performance

**Examples:**
- npm test: `timeout: 60000` (1 min)
- docker build: `timeout: 300000` (5 min)
- long migration: `timeout: 600000` (10 min)

---

## API Integration Agent

### Pattern 1: Assuming API Response Structure
**Mistake:** Access nested fields without checking if they exist (e.g., `data.user.profile.name`)
**Cause:** Assumed API structure from docs without testing
**Correction:** Always verify response structure; use `?` operator or validate before accessing deep fields
**Severity:** MEDIUM
**Tags:** api, assumptions, error-handling, null-safety

**Safe Pattern:**
```javascript
const name = response?.data?.user?.profile?.name || "Unknown";
```

---

### Pattern 2: Ignoring HTTP Status Codes
**Mistake:** Process response without checking HTTP status
**Cause:** Assumed all requests succeed
**Correction:** Always check status code. 2xx = success, 4xx = client error, 5xx = server error
**Severity:** HIGH
**Tags:** api, error-handling, assumptions, http-basics

---

### Pattern 3: Rate Limiting Not Handled
**Mistake:** Make rapid API calls without respecting rate limits; get 429 responses
**Cause:** Didn't read API docs; assumed no rate limit
**Correction:** Check API docs for rate limits; add delays between requests or use batch endpoints
**Severity:** MEDIUM
**Tags:** api, rate-limiting, assumptions, performance

---

## Code Generation Agent

### Pattern 1: Generated Code Without Testing
**Mistake:** Generate code structure without verifying syntax or simple test
**Cause:** Trusted generator output; didn't validate
**Correction:** Generated code should compile/parse before writing to disk
**Severity:** MEDIUM
**Tags:** code-gen, testing, quality, validation

---

### Pattern 2: Hallucinated API Methods
**Mistake:** Generate code calling non-existent API methods
**Cause:** Assumed API from docs without verification
**Correction:** Verify API methods exist. Reference actual source code or recent docs.
**Severity:** HIGH
**Tags:** code-gen, hallucination, api-validation, assumptions

---

## Common Cross-Agent Patterns

### Pattern: "It Looked Right"
**Description:** Agent made assumption based on superficial inspection
**Trigger Phrases:**
- "I thought it would work"
- "Looked like it should be..."
- "Seemed reasonable"

**Correction:** Verify before assuming. Use tools to confirm:
- File structure → read tool
- API behavior → test or check docs
- System state → query with bash
- Permissions → test with actual operation

---

### Pattern: Missing Sequence Steps
**Description:** Agent skipped a validation or setup step in a sequence
**Examples:**
- Git push without status check
- Edit file without reading
- API call without checking auth

**Correction:** Document and enforce sequence in skill/workflow:
```
MUST DO steps:
1. ___
2. ___
3. Only then: ___
```

---

### Pattern: Assumption Over Verification
**Description:** Agent relied on doc/example instead of verifying in current context
**Contexts:**
- API responses vary by endpoint
- Tools work differently on macOS vs Linux
- Project-specific rules differ

**Correction:** Always verify in current context:
- Ask user for project rules
- Test with minimal example
- Check actual responses/outputs
- Verify tool availability

---

## Using These Patterns

### When Reviewing Feedback
1. Match mistake to pattern above
2. Check if it's a new pattern → add to this file
3. Use suggested correction and tags
4. Link to verification steps

### When Creating New Skills
1. Review patterns for your agent type
2. Document preventive rules (what to check before action)
3. Add validation checks to skill
4. Include verification steps

### When Training New Agents
1. Reference patterns most relevant to task
2. Highlight HIGH and CRITICAL severity items
3. Include sequence rules for complex operations
4. Provide real examples (anonymized)

