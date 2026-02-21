# Best Practices for Effective Self-Improvement Feedback

Capturing learnings is only valuable if feedback is specific, actionable, and well-structured. This guide helps you create high-quality feedback.

## Core Principles

### 1. Be Specific, Not Vague

❌ **Bad:**
```
Agent: general
Mistake: Messed up some code
Correction: Do it better
```

✅ **Good:**
```
Agent: file-operations
Mistake: Used edit tool without reading file first; didn't understand file structure
Correction: Always use read tool (with limit param if large) before edit to understand structure and avoid mistakes
```

**Why:** Vague feedback doesn't help other agents. Specific feedback is actionable and applicable to similar situations.

---

### 2. Make Corrections Actionable

❌ **Bad:**
```
Correction: Be more careful with file operations
```

✅ **Good:**
```
Correction: 
1. Before using edit tool, read file with: read(filePath, limit=500)
2. Understand the file structure and syntax
3. Then make surgical edits
4. Test by reading again to verify changes
```

**Why:** Actionable corrections can be taught and verified. They become rules other agents can follow.

---

### 3. Include Discovery Context

❌ **Bad:**
```
Mistake: Didn't check file exists
```

✅ **Good:**
```
Mistake: Didn't verify file path exists before edit
Discovery: Attempted edit on file that was deleted; edit tool accepted the path but edit failed
Context: Tried to edit configuration file that user had deleted. Would have been caught by glob check first.
```

**Why:** Context helps understand when rule applies and why it matters. Prevents false positives.

---

### 4. Use Appropriate Severity

**LOW:** Minor efficiency issue; doesn't break functionality
- Wrong pattern in find command (worked but inefficient)
- Used echo instead of printf (minor style issue)
- Didn't use most efficient API call

**MEDIUM:** Causes task failure; needs workaround; affects correctness
- Assumed API optional field exists (causes crash)
- Edited file without reading (causes syntax errors)
- Didn't check git branch status (causes conflicts)

**HIGH:** Prevents tool usage correctly; safety issue; data loss risk
- Force push without verification
- Edit without reading file
- Direct push without branch check

**CRITICAL:** Causes irreversible harm; security risk; system damage
- Force push to main/master branch
- Deleting protected files
- Exposing secrets or credentials

**Rule of Thumb:** 
- If it breaks the task: MEDIUM+
- If it requires user intervention: HIGH+
- If it could cause data loss: HIGH+
- If it could expose secrets: CRITICAL

---

### 5. Use Tags for Searchability

**Recommended Tags:** (use these consistently)

**By Agent Type:**
- `file-ops`, `file-operations`
- `git`, `git-ops`, `git-workflow`
- `bash`, `bash-execution`
- `api`, `api-integration`, `http`
- `code-gen`, `code-generation`

**By Error Category:**
- `missing-validation`
- `assumption-error`
- `sequence-mistake`
- `safety-issue`
- `tool-misuse`
- `error-handling`
- `null-safety`
- `edge-case`

**By Impact:**
- `data-loss`
- `branch-tracking`
- `permissions`
- `rate-limiting`
- `timeout`
- `cross-platform`

**Example:**
```
Tags: file-ops, safety, sequence-mistake, missing-validation
```

This makes feedback searchable and groupable: "Show me all HIGH severity file-ops mistakes"

---

### 6. Add Real Examples (When Applicable)

❌ **Bad:**
```
Mistake: API error handling could be better
```

✅ **Good:**
```
Mistake: Didn't check HTTP status code before processing response

Example:
```
const response = await fetch(url);
const data = response.json();  // ❌ Won't work if status is 404
```

Should be:
```
const response = await fetch(url);
if (!response.ok) {
  throw new Error(`API error: ${response.status}`);
}
const data = response.json();  // ✅ Safe now
```
```

**Why:** Examples make the lesson concrete and referable.

---

## Structured Feedback Format

Use this template for consistent, high-quality feedback:

```
Agent: [agent type]
Mistake: [what went wrong - 1-2 sentences]
Discovery: [how/when you realized it]
Context: [why it mattered in this situation]
Correction: [specific fix - step by step]
Severity: [low|medium|high|critical]
Category: [missing-validation|assumption-error|sequence-mistake|safety-issue|etc]
Tags: [tag1,tag2,tag3]
Examples: [optional - real code or scenario]
Prevention: [how to catch before happening]
Related: [link to similar feedback or skill]
```

---

## Category Guide

**Use these categories consistently:**

### missing-validation
Forgot to check something before acting.
- Didn't read file before editing
- Didn't verify file exists before operation
- Didn't check API response structure
- Didn't verify branch is clean before push

### assumption-error
Assumed something was true without verifying.
- Assumed API endpoint exists
- Assumed field is always present
- Assumed tool is installed
- Assumed file format from name only

### sequence-mistake
Skipped a step in required sequence.
- Push without git status/fetch
- Edit without read
- API call without auth check
- Deploy without tests

### safety-issue
Action could cause harm if wrong.
- Force push without verification
- Delete without backup check
- Write without read first
- Run dangerous command without confirmation

### tool-misuse
Used tool incorrectly or inefficiently.
- Wrong regex syntax in find
- Inefficient bash pipes
- Misunderstood tool parameters
- Used deprecated API

### error-handling
Didn't handle predictable errors.
- Didn't check HTTP status
- No null check on API fields
- Didn't handle missing files
- No timeout on long operations

---

## Common Scenarios

### Scenario 1: User Corrects You

**Your feedback:**
```
Agent: [your type]
Mistake: [what you did wrong]
Correction: [what user showed you]
Discovery: User corrected during [task type]
Severity: medium (user had to intervene)
Category: [best fit]
Tags: user-correction, [other tags]
```

**Example:**
```
Agent: file-operations
Mistake: Used edit tool without reading file first
Correction: Always read file first to understand structure, then edit surgically
Discovery: User said "You should read first!" during file editing task
Severity: medium
Category: missing-validation
Tags: file-ops, safety, sequence, user-feedback
```

---

### Scenario 2: You Discover Edge Case

**Your feedback:**
```
Agent: [your type]
Mistake: [assumption you made that broke]
Discovery: Found when [describe situation]
Context: Caused [specific failure mode]
Correction: [exact rule to avoid it]
Severity: [impact of failure]
Category: assumption-error or edge-case
Tags: edge-case, [domain], [specific-thing]
Prevention: Check for [specific condition] before [action]
```

**Example:**
```
Agent: api-integration
Mistake: Assumed API optional field would always be present in response
Discovery: API returned null for 'location' field on some records
Context: Caused JSON parsing error, task failed
Correction: Use safe access for optional fields: response?.data?.location || null
Severity: medium
Category: assumption-error
Tags: api, null-safety, optional-fields
Prevention: Check API docs for "optional" fields; always use safe access or validate before use
```

---

### Scenario 3: Tool Usage Mistake

**Your feedback:**
```
Agent: bash-executor
Mistake: [what you did wrong with tool]
Why: [why it seemed right]
Correction: [right way to use tool]
Severity: low (worked but inefficient) to medium (didn't work)
Category: tool-misuse or error-handling
Tags: bash, [tool-name], [aspect]
Prevention: Test pattern first with simple input
Examples: [show wrong vs right usage]
```

**Example:**
```
Agent: bash-executor
Mistake: Used glob pattern without quotes in bash command
Why: Thought shell would handle it correctly
Correction: Always quote glob patterns: "**/*.js" not **/*.js
Severity: low
Category: tool-misuse
Tags: bash, quoting, glob-patterns
Prevention: Quote all glob patterns in bash commands
Example:
  ❌ find . -name *.js
  ✅ find . -name "*.js"
```

---

## Anti-Patterns to Avoid

### ❌ Too Generic
"I should be more careful" → Not actionable, won't help others

### ❌ Blame-focused
"I'm not good at API integration" → Focus on mistake, not ability

### ❌ Multi-mistake feedback
"I read wrong, edited without thinking, didn't test" → One feedback per mistake

### ❌ Feedback that can't be verified
"I should understand better" → Make it measurable: "Should verify response structure"

### ❌ Feedback with no severity justification
"This is high severity" → Explain: "High because it blocks other agents and causes data loss"

---

## Quality Checklist

Before capturing feedback, verify:

- [ ] **Specific:** Feedback is specific enough that another agent could follow it
- [ ] **Actionable:** Someone could take the correction and apply it
- [ ] **Contextual:** Clear why it mattered / when it applies
- [ ] **Appropriate severity:** Justified by actual impact
- [ ] **Consistent tags:** Using tags from the feedback-patterns guide
- [ ] **Single focus:** One mistake per feedback (not bundled)
- [ ] **Verifiable:** Could test that someone following the rule prevents issue
- [ ] **Non-defensive:** Focuses on learning, not blame

---

## Example: High-Quality Feedback

```
Agent: file-operations
Mistake: Used edit tool to modify config file without reading it first

Discovery: Attempted to edit ~/.config/app.json, edit succeeded but file syntax 
became invalid. Realized I should have read file first to understand structure.

Context: Edited JSON file; didn't understand nesting level, made incorrect edits 
that broke app startup. User had to fix manually.

Correction:
1. Before editing ANY file, use read(filePath, limit=1000) to understand structure
2. For large files, use limit parameter to read first N lines
3. Understand syntax/format before making edits
4. After edit, read again to verify changes look correct

Prevention: Add pre-edit validation that reads file first

Severity: HIGH
Category: missing-validation
Tags: file-ops, safety, sequence, edit-pattern

Related: Similar feedback from bash-executor on json parsing
```

**Why this works:**
- ✅ Specific (edit, config file, JSON syntax)
- ✅ Actionable (exact steps: read, understand, edit, verify)
- ✅ Contextual (caused invalid JSON, user had to fix)
- ✅ Appropriate severity (safety issue, user intervention needed)
- ✅ Verifiable (could write rule: "read before edit")
- ✅ Non-defensive (focused on learning)

---

## Continuous Improvement

### Review Your Feedback Monthly

```bash
aimeta self-improvement export --format markdown --since "1-month-ago" > feedback.md
```

Then:
- Look for patterns you personally repeat
- See if corrections helped (pattern stopped appearing?)
- Note what's been addressed (new skills created?)
- Identify high-impact learnings to share

### Help Others Learn

When you see another agent making mistake:
- Don't just fix it; help them capture the learning
- "Would you like to use self-improvement skill to capture this?"
- Point them to relevant patterns in feedback-patterns.md

### Build Institutional Knowledge

- Review feedback regularly to identify skill candidates
- Create PRs documenting new patterns
- Reference feedback in skill documentation
- Link feedback to code examples

