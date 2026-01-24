---
name: 360-feedback
description: Request 360 feedback from sub-agents to improve prompt clarity, context delegation, and overall orchestration quality.
author: Cristian Oliveira
version: 0.1.0
---

# 360 Feedback Command

Use this command when you (the orchestrator) want to collect structured feedback from sub‑agents about the quality of your prompts, the context you provided, and suggestions for better delegation.

## How to Request Feedback

1. **Select the sub‑agents** that participated in the task (or a representative sample).
2. **When using the Task tool** to spawn each sub‑agent include the feedback request.
3. **Provide the feedback template** below as part of the prompt.
4. **Ask each sub‑agent** to respond with the completed template in their final message.

## Feedback Template for Sub‑Agents

Include the following section in your prompt to the sub‑agent:

```markdown
### 360 Feedback Request

Please provide constructive feedback on the prompt and context you received for this task. Your feedback will help improve future delegations.

**Please respond with the following structure:**

#### Prompt Clarity
- What was clear and well‑defined in the prompt?
- What was ambiguous or confusing?

#### Missing Context
- What additional information would have helped you complete the task more effectively?
- Were there assumptions you had to make that should have been explicit?

#### Improvements
- How could the prompt be rewritten to be more effective?
- What specific changes would make the task easier to understand and execute?

#### Context Delegation Suggestions
- What type of context (code snippets, examples, references, etc.) would have been most valuable?
- How could the orchestrator better pass relevant background information?

#### Overall Rating (1‑5)
- 1 = Very poor, 5 = Excellent
- Brief justification for your rating.
```

## Orchestrator Instructions

1. **Tailor the request** – adjust the template based on the specific task and sub‑agent type.
2. **Keep it concise** – sub‑agents are busy; focus on the most important feedback areas.
3. **Synthesize responses** – after collecting feedback, look for common patterns and actionable insights.
4. **Update your delegation practices** – use the feedback to refine future prompts and context sharing.

## Example Usage

```markdown
## Collect and store
Collect all feedback and apend in `.tmp/reports/360‑feedback‑kubernetes‑scheduler.md` and summarize key improvements.
```

## Output Format
Sub‑agents should return their feedback in the exact template structure above. As the orchestrator, compile all responses into a single report file (e.g., `.tmp/reports/360‑feedback‑<task‑name>.md`) with:

${for each feedback}
---
task: ${feedback.task}
summary: ${feedback.summary}
---
${end for}

## Notes

- This command is meant for the orchestrator, not for direct execution by sub‑agents.
- The feedback template is intentionally generic; adapt it to the specific sub‑agent type (e.g., task‑worker vs. researcher).
- Always thank sub‑agents for their feedback and acknowledge their contributions.
