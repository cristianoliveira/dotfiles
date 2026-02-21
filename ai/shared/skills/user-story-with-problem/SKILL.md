---
name: user-story-with-problem
description: Write effective user stories that start with the problem statement. Define the business problem first, then capture requirements from the user's perspective with clear acceptance criteria.
---

# User Story Writing (Problem-First)

## Overview

Well-written user stories begin with understanding **the problem we're solving**, not just what the user wants. This approach ensures:
- Stories solve real business problems
- Requirements connect to business value
- Everyone understands the "why"
- Solutions are focused and effective

## When to Use

- Breaking down requirements into development tasks
- Product backlog creation and refinement
- Agile sprint planning
- Communicating features to development team
- Defining acceptance criteria
- Creating test cases
- **Understanding the business problem FIRST**

## Critical: Problem Statement First

### Why Problem Statements Matter

Before writing any user story, ask:
- **What problem are we solving?**
- **Who has this problem?**
- **Why does it matter?**
- **What's the business impact?**

Stories without problem statements are solutions looking for problems. Stories WITH clear problem statements drive better decisions and outcomes.

---

## Instructions

### 1. **Define the Problem Statement First**

```markdown
# Problem Statement

## The Problem
[Clear, specific description of the problem]

## Who Has This Problem?
[User personas/roles affected]

## Current State (As-Is)
[How things work today]
[Pain points experienced]
[Inefficiencies or failures]

## Impact
- Business impact: [Revenue loss, customer churn, inefficiency, etc.]
- User impact: [Frustration, time wasted, errors, etc.]
- Technical impact: [System limitations, maintenance burden, etc.]

## Why Now?
[What triggered the need to solve this now?]
```

### Example Problem Statement

```markdown
# Problem Statement: Slow Checkout Process

## The Problem
Customers abandon their carts during checkout because the process is slow and has unclear steps, resulting in 40% cart abandonment rate.

## Who Has This Problem?
- Customers trying to purchase (friction, abandonment)
- Business (lost revenue)
- Support team (customer complaints)

## Current State (As-Is)
- Multi-step form requires 8-10 minutes to complete
- No progress indicator, users unsure how many steps remain
- Validation errors not clearly indicated
- Payment processing has no timeout feedback

## Impact
- Business impact: $50K/month revenue loss from cart abandonment
- User impact: Frustration, 8-10 minute process feels excessive
- Technical impact: Form validation scattered across codebase

## Why Now?
New competitor launched with 2-minute checkout; we're losing customers to faster experience.
```

---

### 2. **User Story Format (After Problem is Clear)**

```markdown
# User Story Template

**Problem**
[Reference to problem statement]

**Use Case**
**As a** [user role/persona]
**I want to** [action/capability]
**So that** [business value/benefit]

---

## User Context

- User Role: [Who is performing this action?]
- User Goals: [What are they trying to accomplish?]
- Use Case: [When do they perform this action?]
- Pain Point Addressed: [Which part of the problem does this solve?]

---

## Acceptance Criteria

Given [precondition]
When [action]
Then [expected result]

Example:
Given a user is logged in and viewing their cart
When they begin checkout
Then they see a progress indicator showing 3 steps
And the first step is focused
And they can navigate to previous steps

---

## Definition of Done

- [ ] Code written and peer reviewed
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests passing
- [ ] Acceptance criteria verified
- [ ] Documentation updated
- [ ] No console errors or warnings
- [ ] Performance acceptable
- [ ] Accessibility requirements met
- [ ] Security review completed
- [ ] Product owner approval
- [ ] Solves the stated problem (validation with users)

---

## Additional Details

**Story Points:** 5 (estimate of effort)
**Priority:** High
**Epic:** [Parent feature]
**Sprint:** Sprint 23
**Assignee:** [Developer]
**Dependencies:** [Other stories this depends on]
**Problem Metric:** [How do we measure if this solves the problem?]

---

## Notes

- Any additional context or considerations
- Edge cases to consider
- Performance constraints
- Accessibility requirements
- Security considerations
```

### Example User Story (Connected to Problem)

```markdown
# User Story: Add Checkout Progress Indicator

**Problem Being Solved:** Slow Checkout Process - Users don't know how many steps remain, causing confusion and abandonment

**Title:** Display checkout progress indicator

**As a** customer completing a purchase
**I want to** see which step I'm on and how many remain
**So that** I understand the process and feel confident continuing

---

## User Context

- User Role: Customers purchasing products
- User Goals: Complete purchase as quickly as possible
- Use Case: During checkout flow
- Pain Point Addressed: "I don't know how many steps I have to complete" - causes uncertainty

---

## Acceptance Criteria

Scenario 1: Progress indicator displays on step 1
  Given I've added items to my cart
  When I click "Checkout"
  Then I see "Step 1 of 3" prominently displayed
  And the current step is visually highlighted
  And previous steps are disabled (grayed out)

Scenario 2: Progress updates on navigation
  Given I'm on step 1 of 3
  When I complete the form and click "Next"
  Then the progress updates to "Step 2 of 3"
  And I can see I've made progress
  And I can click "Back" to return to step 1

Scenario 3: Final step indicates completion
  Given I'm on step 3 of 3
  When I view the payment form
  Then it shows "Step 3 of 3 - Final Step"
  And the submit button says "Complete Purchase"
  And I feel confident this is the end

Scenario 4: Mobile responsiveness
  Given I'm viewing on a mobile device
  When I load any checkout step
  Then the progress indicator is clearly visible
  And it doesn't take up excessive vertical space
  And it's easy to tap "Back" if needed

---

## Definition of Done

- [ ] Code written and peer reviewed
- [ ] Unit tests written for progress state management
- [ ] Integration tests for step transitions
- [ ] Acceptance criteria verified with QA
- [ ] Progress indicator displays on all 3 steps
- [ ] Mobile responsive tested on iOS and Android
- [ ] Accessibility: Aria labels on progress
- [ ] No console errors
- [ ] Performance: <100ms to update progress
- [ ] Product owner approval
- [ ] User testing shows reduced confusion
- [ ] Checkout completion rate improved

---

## Additional Details

**Story Points:** 5
**Priority:** High
**Epic:** Improve Checkout Experience
**Sprint:** Sprint 24
**Assignee:** Frontend Team
**Dependencies:** None
**Problem Metric:** Measure checkout step abandonment rate - should decrease

---

## Notes

- Keep progress indicator visible while scrolling
- Test on common devices (iPhone 12, Samsung S21, iPad)
- Consider animation to show progress (subtle, not distracting)
- Update progress state in analytics for tracking
```

---

### 3. **Story Refinement Process (Problem-Aware)**

Ask these questions during refinement:

```markdown
## Refinement Checklist

### Problem Clarity
- [ ] Is the problem statement clear and agreed upon?
- [ ] Does everyone understand WHY we're solving this?
- [ ] Is the problem quantified (metrics, impact)?
- [ ] Have we validated this is a real problem with users?

### Story Quality (INVEST Criteria)
- [ ] **Independent**: Story can be implemented independently
- [ ] **Negotiable**: Details can be discussed and refined
- [ ] **Valuable**: Delivers clear business value (connected to problem)
- [ ] **Estimable**: Team can estimate effort
- [ ] **Small**: Can be completed in one sprint
- [ ] **Testable**: Clear acceptance criteria proving it solves the problem

### Problem Validation
- [ ] How will we measure if this story solves the problem?
- [ ] What user feedback validates this works?
- [ ] Should we include metrics/analytics in "Definition of Done"?

### Story Splitting
- [ ] Can we split this story to deliver problem-solving value faster?
- [ ] Should we ship the MVP that solves the core problem first?
```

---

### 4. **Acceptance Criteria Examples (Problem-Focused)**

```yaml
# Example 1: Solving "Slow Checkout" Problem
Story: Add progress indicator

Acceptance Criteria:

Scenario 1: Progress displays
  Given user begins checkout
  When they view any step
  Then they see progress (e.g., "Step 2 of 3")
  And the metric "users who abandon without progress indicator" decreases

Scenario 2: Multiple steps visible
  Given user is on step 2
  When they look at the progress
  Then they can see 3 steps clearly labeled
  And step 2 is highlighted as current
  And they can navigate backward

---

# Example 2: Solving "Users Can't Find Features" Problem
Story: Improve feature discoverability

Acceptance Criteria:

Scenario 1: Search functionality works
  Given a user wants to find a feature
  When they type in the search box
  Then results appear within 500ms
  And the metric "feature discovery time" decreases from 5 min to <1 min

Scenario 2: Help system prominent
  Given user is confused about a feature
  When they look for help
  Then contextual help appears
  And the metric "support tickets for feature X" decreases

Non-Functional Requirements:
  - Performance: Search returns results in <500ms
  - Usability: Users find feature in <1 minute (validated with user testing)
  - Success: Support ticket volume for this feature decreases by 30%
```

---

### 5. **Story Splitting Strategy**

When you have a problem statement, split stories to deliver value incrementally:

```markdown
## Story Splitting (Problem-First)

### Original Problem
Customers abandon checkout due to slow, confusing process.

### Split by Value Delivery (MVP First)

Story 1: "Add progress indicator" (3 points) - SOLVES CORE PROBLEM
  - Shows user where they are in process
  - Reduces confusion
  - Measurable: Completion rate improves

Story 2: "Reduce form fields" (5 points) - COMPOUND THE VALUE
  - Remove optional fields
  - Reduce checkout time
  - Measurable: Completion time decreases

Story 3: "Add saved addresses" (3 points) - INCREMENTAL IMPROVEMENT
  - Remember previous addresses
  - Skip address step on future purchases
  - Measurable: Repeat customer experience improved

Story 4: "Express checkout option" (5 points) - ADVANCED FEATURE
  - Single-click checkout for returning customers
  - Maximum speed
  - Measurable: Conversion rate increases

### Why This Matters
- Story 1 solves the CORE PROBLEM (confusion)
- Can be shipped independently and tested
- Stories 2-4 compound the value
- Each story adds measurable improvement
- Can gather user feedback early
```

---

### 6. **Measuring Success (Problem Validation)**

```markdown
## How Do We Know the Problem Is Solved?

For each user story, define:

### Problem Metric
"The problem is solved when: [metric improves]"

Examples:
- Checkout abandonment rate decreases from 40% to <20%
- Feature discovery time decreases from 5 minutes to <1 minute
- Support tickets for this feature decrease by 50%
- User satisfaction score increases from 2/5 to 4/5
- Completion rate increases from 60% to 85%

### Story Acceptance Criteria
"This story is done when: [specific behaviors work]"

Example:
- Progress indicator displays on all 3 steps
- Updates correctly when navigating
- Mobile responsive
- Tests pass
- No console errors

### Success Validation
After shipping, measure:
- Did the metric move in the right direction?
- Did users validate the problem is solved?
- What did we learn?
- Should we iterate or move to next problem?
```

---

## Best Practices

### ✅ DO
- **Start with the problem statement** - understand the "why" first
- Write from the user's perspective
- Focus on value, not implementation
- Create stories small enough for one sprint
- Define clear acceptance criteria
- Use consistent format and terminology
- Have product owner approve stories
- Include edge cases and error scenarios
- Link to problem statement and business goals
- Update stories based on learning
- Create testable stories
- **Define metrics to prove the problem is solved**
- **Validate with users that the problem actually exists**

### ❌ DON'T
- Write user stories without problem statements
- Write technical task-focused stories
- Create overly detailed specifications
- Write stories that require multiple sprints
- Forget about non-functional requirements
- Skip acceptance criteria
- Create dependent stories unnecessarily
- Write ambiguous acceptance criteria
- Ignore edge cases
- Create too large stories
- Change stories mid-sprint without discussion
- **Ship without validating the problem is solved**
- **Assume you know the problem without talking to users**

## User Story Tips

- Start with "What problem are we solving?"
- Keep stories focused on user value
- Use story splitting when >5 points
- Always include acceptance criteria
- Review stories with team before sprint
- **Include metrics in "Definition of Done"**
- **Measure success after shipping**
- Update definitions of done as team learns
- **Connect stories back to the original problem statement**

---

## Quick Template (Copy-Paste Ready)

```markdown
# Problem Statement
[Description]

## Impact
- Business impact: [Financial, customer, etc.]
- User impact: [Frustration, inefficiency, etc.]
---

# User Story: [Story Title]

**Problem Being Solved:** [Reference to problem statement]

**As a** [user role]
**I want to** [action]
**So that** [benefit]

---

## Acceptance Criteria

Given [precondition]
When [action]
Then [expected result]

```
