# Jira Task Template

## Template Structure

```markdown
# Description

{Problem description}

## Acceptance criteria
- {Acceptance criteria 1}
- {Acceptance criteria 2}
- {Acceptance criteria 3}
- {etc}

## Screenshots (if applicable)

{Screenshot}
{Notes about screenshot}

## Relevant links (if applicable)

{Links}
```

## Field Explanations

### Description
Provide a clear, concise description of the problem or requirement. Include:
- What needs to be done
- Why it's important
- Any relevant context or background
- Impact if not addressed

### Acceptance Criteria
Bullet-point list of measurable criteria that must be met for the task to be considered complete. Each criteria should be:
- Specific and testable
- Focused on outcome, not implementation
- Written in plain language
- Include any edge cases or considerations

Examples:
- "User can successfully log in with valid credentials"
- "Error message appears when invalid email format is entered"
- "Mobile responsive design matches Figma mockups"

### Screenshots
Include when visual context is needed:
- Bug reports with UI issues
- Design references
- Before/after comparisons

Format: `![Alt text](image-url)` or attach files directly in Jira

### Relevant Links
Include references to:
- Related documentation
- Design files (Figma, Sketch)
- PRs or other tickets
- External resources

## Template Usage

When creating the Jira issue description, this template should be filled with the gathered information. The final description will be passed to `jira issue create` via the `-b` (body) flag or `--template` flag if saved to a file.