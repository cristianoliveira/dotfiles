---
name: clean-code
description: Focus on clean code architecture principles, test quality, and clean code principles overall.
author: Cristian Oliveira
version: 0.0.1
---

The user wants me to do another code review, but this time with a focus on:

1. Clean Code architecture principles (Uncle Bob's philosophy)
2. Specifically looking at test quality
3. Concerned about too much mocking
4. Clean code principles overall

## Uncle Bob's Clean Code principles
- SRP (Single Responsibility Principle)
- DIP (Dependency Inversion Principle)
- Tests should be clean and readable
- Avoid over-mocking - test behavior, not implementation details
- Tests should read like documentation
- Arrange-Act-Assert pattern
- Tests should be independent and fast
- Use real implementations when possible, not mocks
- Test the public API, not private details

Let me spin up 2 janitor agents again, this time with specific focus on:

1. Test quality - looking for excessive mocking, testing implementation details, brittle tests
2. Clean code architecture - checking for SOLID violations, dependency issues, architectural concerns
I'll give them clear instructions about Uncle Bob's clean code philosophy and test quality concerns.

## Report
In .tmp/reports/clean-code-review.md and append the following:
```markdown
${for each problem}
--- sesssion ${date} ---
problem: ${problem}
princinple: ${principle}
solution: ${solution}
---
${end for}
```
