# Integration Guide: Self-Improvement in Agent Workflows

This guide explains how to integrate self-improvement feedback capture into agent workflows and how the ecosystem uses learnings.

## Workflow Integration Points

### 1. Error Recovery Workflow

**When:** Agent discovers mistake during task execution

```
Agent realizes mistake
  ↓
Agent analyzes what went wrong
  ↓
Agent captures with self-improvement skill
  ↓
Agent continues/fixes task
  ↓
At completion: agent exports learnings
```

**Implementation:**
```bash
# Mid-task discovery
aimeta self-improvement add \
  --agent "file-operations" \
  --mistake "Didn't verify file path exists before edit" \
  --correction "Use glob to verify file exists first" \
  --category "missing-validation" \
  --severity "high" \
  --context "Tried to edit file that was deleted"

# Continue with fix
# ... fix the actual issue ...

# At task end, export
aimeta self-improvement export --format markdown
```

---

### 2. User Correction Workflow

**When:** User corrects agent or suggests better approach

**Agent:** Recognize correction signals
```
User says: "You should have done X instead"
  ↓
Agent responds: "I see, let me capture that learning"
  ↓
aimeta self-improvement add [correct approach]
  ↓
Agent applies correction
  ↓
Agent verifies fix works
```

**Example Dialog:**
```
User: "You're editing that file without reading it first. Always read first!"

Agent: "You're absolutely right. Let me capture that learning."

aimeta self-improvement add \
  --agent "file-operations" \
  --mistake "Edited file without reading first to understand structure" \
  --correction "Always use read tool first. For large files, use limit param." \
  --category "missing-validation" \
  --severity "high" \
  --tags "file-ops,safety,sequence" \
  --context "User corrected me during file editing task"

Agent: "Captured. I'll apply this: [showing the learned rule]"
```

---

### 3. Edge Case Discovery Workflow

**When:** Agent encounters edge case that could recur

```
Task progresses normally
  ↓
Agent hits unexpected behavior/edge case
  ↓
Agent investigates root cause
  ↓
Agent captures pattern for future
  ↓
Agent handles current case
  ↓
Export learnings for similar tasks
```

**Example:**
```bash
# Task: Parse JSON from API
# Discovery: API sometimes returns null for optional field

aimeta self-improvement add \
  --agent "api-integration" \
  --mistake "Assumed optional API field would always be present" \
  --correction "Use safe access for optional fields: data?.field || default" \
  --category "assumption-error" \
  --severity "medium" \
  --context "API returned null for location field, caused JSON parse error"
```

---

## Orchestrator Agent Integration

### Role: Suggest Feedback Capture

Orchestrator agents monitor other agents and can suggest skill usage:

```python
def monitor_agent_execution(agent_output):
    """Orchestrator monitoring other agents."""
    
    if agent_output.has_error and agent_output.discovered_root_cause:
        suggest_skill_usage(
            skill="self-improvement",
            reason="Agent discovered root cause of error",
            context=agent_output.error_analysis
        )
    
    if agent_output.was_corrected_by_user:
        suggest_skill_usage(
            skill="self-improvement",
            reason="User provided correction or better approach",
            context=agent_output.user_feedback
        )
    
    if agent_output.found_new_edge_case:
        suggest_skill_usage(
            skill="self-improvement",
            reason="Discovered edge case that could affect future tasks",
            context=agent_output.edge_case_details
        )
```

---

## Skill Creator Integration

### Use Case 1: Feedback Review for New Skill

New skills can be created from high-impact learnings:

```bash
# 1. Review exported learnings
aimeta self-improvement export --format markdown > learnings.md

# 2. Identify patterns (high severity + repeated)
# Example: 10 different agents all made "edit-without-read" mistake

# 3. Create new preventive skill
aimeta skill-creator create \
  --name "always-read-first" \
  --description "Validate file before edit: always read first" \
  --based-on "learnings.md" \
  --triggers "edit,file,write" \
  --integrates-with "file-operations"
```

### Use Case 2: Add Validation Rules to Existing Skill

Learnings can enhance existing skills:

```bash
# 1. Review HIGH severity learnings in a category
aimeta self-improvement export --format json --category "git" | jq '.[] | select(.severity=="high")'

# 2. Update git-workflow skill with new guards
# Example: Add check for "no force push to main"

aimeta skill-creator enhance \
  --skill "git-workflow" \
  --add-guard "prevent-force-push-to-protected-branches" \
  --learned-from "learnings.md" \
  --impact "safety: prevents data loss"
```

---

## Periodic Review Cycle

### Weekly Review
```bash
# Sunday evening: review week's learnings
aimeta self-improvement review-session --since "last-week"

# Output: categorized list, pattern detection
# Action: merge duplicates, mark high-severity items
```

### Monthly Export & Share
```bash
# Export for sharing with ecosystem
aimeta self-improvement export \
  --format markdown \
  --output "learnings-$(date +%Y-%m).md" \
  --since "1-month-ago"

# Actions:
# - Share with team
# - Create pull request to document patterns
# - Identify candidates for new skills
```

### Quarterly Skill Creation
```bash
# Review 3 months of high-severity patterns
aimeta self-improvement export \
  --format json \
  --since "3-months-ago" > quarterly_learnings.json

# Analyze: Which patterns appeared most?
# Which have highest impact?
# Which warrant new skill?

# Create skills for top patterns
```

---

## Integration with Agent Training

### Using Learnings for New Agent Training

When training a new agent, reference learnings:

```markdown
## Agent Training Package

### Included Learnings
- File operations: [feedback-patterns.md#file-operations-agent]
- Git operations: [feedback-patterns.md#git-operations-agent]
- API integration: [feedback-patterns.md#api-integration-agent]

### Critical Rules (from learnings)
1. **File ops:** Always read first, never assume structure
2. **Git ops:** Always check branch status before push
3. **API ops:** Always verify response structure, check status codes

### Common Mistakes to Avoid
[from self-improvement export categorized by severity]
```

---

## Integration with Monitoring & Alerting

### Alert on Pattern Threshold

Monitor learnings for concerning patterns:

```bash
# Script: weekly-pattern-check.sh
aimeta self-improvement export --format json > current_week.json

# Alert if any pattern appears 5+ times
# Alert if any HIGH severity item is new (not in last month)
# Alert if CRITICAL severity discovered

if [ $(jq '[.[] | select(.severity=="high")] | length' current_week.json) -gt 3 ]; then
    notify "High severity learnings increased - review needed"
fi
```

---

## Integration with Knowledge Base

### Export to Knowledge Base System

Learnings can feed into a knowledge base:

```bash
# 1. Export structured data
aimeta self-improvement export \
  --format json \
  --category "all" \
  --output kb-import.json

# 2. Process and import to KB
kb-import.sh kb-import.json \
  --tag "agent-learnings" \
  --link-to-skills \
  --update-triggers

# 3. Make learnings discoverable
kb-search "edit-without-read" → shows:
  - Feedback entries
  - Related skills
  - Prevention tips
  - Link to feedback-patterns.md
```

---

## Best Practices for Integration

### 1. **Suggest at Right Time**
- Suggest after agent identifies root cause (not every error)
- Suggest when user provides explicit feedback
- Suggest for NEW patterns (not duplicates of recent learning)

### 2. **Link Feedback to Actions**
- Each HIGH/CRITICAL feedback should have action plan
- Map feedback to either: skill update, new skill, or training change
- Track which feedback was acted upon

### 3. **Avoid Feedback Spam**
- Dedup: "forgot to read file" captured multiple times = one entry
- Combine: similar corrections → one pattern with multiple examples
- Archive: low-impact, resolved items that won't recur

### 4. **Make Learnings Accessible**
- Export regularly to markdown for human review
- Link feedback entries to code examples
- Tag consistently for searching
- Provide feedback statistics: "Most common mistake this month: ___"

### 5. **Close the Loop**
- When feedback leads to skill/training change, mark as addressed
- Verify: did fix work? Did pattern stop appearing?
- Report back: "Fixed pattern X - haven't seen it in 3 weeks"

---

## Example: End-to-End Integration

### Scenario: File Edit Mistakes Appearing Often

```
Day 1: Agent discovers "edit without read" mistake
  → Captures with self-improvement

Days 2-5: Three more agents make same mistake
  → Each captures with self-improvement

Week 1 Review: Detect pattern
  → Same mistake, high severity, 4 occurrences
  → Marked as "candidate for preventive skill"

Week 2: Decision to create new skill
  → aimeta skill-creator create --based-on "learnings"
  → Create "always-read-first" skill
  → Add to agent training

Week 3+: Monitor
  → Pattern doesn't appear in new feedback
  → Learnings now reference new skill
  → Success: integrated learning into ecosystem
```

---

## Troubleshooting Integration Issues

### Issue: Too Much Feedback, Low Signal
**Solution:** 
- Increase severity threshold for review
- Dedup by pattern before exporting
- Focus on HIGH/CRITICAL only

### Issue: Feedback Captured But Not Acted Upon
**Solution:**
- Monthly review of export → action plan
- Track feedback → skill/training linkage
- Report metrics: "Feedback → Action rate: X%"

### Issue: New Agents Don't Know About Learnings
**Solution:**
- Include learnings in agent training package
- Reference patterns in skill documentation
- Link skills to origin feedback

