---
name: react-testing
description: Review and create React tests following best practices from React Testing Library and Kent C. Dodds' principles. Use when user wants to (1) write new React component tests, (2) review existing test code, (3) fix failing tests, (4) improve test quality and coverage, or asks "should I test this?", "how do I test this component?", "review my React tests"
---

# React Testing Skill

## Quick Start

When reviewing or writing React tests, follow these core principles:

1. **Test behavior, not implementation** - Query by what users see (text, role, label), not by class or ID
2. **Avoid testing internal state** - Don't test state directly; verify output changes
3. **Use descriptive test names** - Avoid "should work" or "should render". Use specific behavior descriptions
4. **Minimize mocking** - Mock external dependencies only (API calls, timers), not implementation details
5. **Avoid snapshot testing** - Use specific assertions instead

## Test Naming Convention

**❌ Bad:**
```javascript
it('should render', () => {
it('should work', () => {
it('handles click', () => {
```

**✅ Good:**
```javascript
it('displays the user name when loaded', () => {
it('submits the form when submit button is clicked', () => {
it('shows an error message when email is invalid', () => {
```

The test name should describe **what the user sees or experiences**, not what the code does.

## Common Queries (Best to Worst)

Use queries in this order:

```javascript
// ✅ Best - User-centric, accessible
screen.getByRole('button', { name: /submit/i })
screen.getByLabelText('Email')
screen.getByPlaceholderText('Enter name')
screen.getByText('Welcome')

// ⚠️ Last resort - Implementation details
screen.getByTestId('submit-btn')
```

## Common Mistakes to Avoid

### 1. Mocking Implementation Details

**❌ Bad:**
```javascript
jest.mock('../hooks/useUser', () => ({
  useUser: () => ({ setName: jest.fn(), name: 'John' })
}));
```

**✅ Good:**
```javascript
// Mock only the API call, not the hook logic
jest.mock('../api/userService');
userService.fetchUser.mockResolvedValue({ name: 'John' });
```

### 2. Snapshot Testing

**❌ Bad:**
```javascript
it('renders correctly', () => {
  render(<Component />);
  expect(container).toMatchSnapshot();
});
```

**✅ Good:**
```javascript
it('displays user greeting', () => {
  render(<Component name="John" />);
  expect(screen.getByText('Hello, John')).toBeInTheDocument();
});
```

### 3. Testing Internal State

**❌ Bad:**
```javascript
const { rerender } = render(<Counter initialValue={0} />);
expect(component.state.count).toBe(0);
```

**✅ Good:**
```javascript
render(<Counter initialValue={0} />);
expect(screen.getByText('Count: 0')).toBeInTheDocument();
```

### 4. Not Waiting for Async Operations

**❌ Bad:**
```javascript
render(<UserProfile userId="123" />);
expect(screen.getByText('John')).toBeInTheDocument();
```

**✅ Good:**
```javascript
render(<UserProfile userId="123" />);
const username = await screen.findByText('John');
expect(username).toBeInTheDocument();
```

Or with `waitFor`:
```javascript
render(<UserProfile userId="123" />);
await waitFor(() => {
  expect(screen.getByText('John')).toBeInTheDocument();
});
```

## Testing Patterns

### User Interaction Pattern

```javascript
it('adds item to list when form is submitted', async () => {
  render(<TodoList />);

  const input = screen.getByLabelText('New todo');
  const submitBtn = screen.getByRole('button', { name: /add/i });

  await user.type(input, 'Buy milk');
  await user.click(submitBtn);

  expect(screen.getByText('Buy milk')).toBeInTheDocument();
});
```

### API Call Pattern

```javascript
it('displays user data after loading', async () => {
  jest.mock('../api/userService');
  userService.getUser.mockResolvedValue({ name: 'Jane', id: 1 });

  render(<UserCard userId="1" />);

  const name = await screen.findByText('Jane');
  expect(name).toBeInTheDocument();
});
```

### Conditional Rendering Pattern

```javascript
it('shows loading state initially and data after loading', async () => {
  render(<DataComponent />);

  expect(screen.getByText(/loading/i)).toBeInTheDocument();

  const data = await screen.findByText('Data loaded');
  expect(data).toBeInTheDocument();
  expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
});
```

## Assertions

Use semantic assertions:

```javascript
// ✅ Preferred
expect(element).toBeInTheDocument();
expect(element).toBeDisabled();
expect(element).toHaveClass('active');
expect(input).toHaveValue('text');

// ❌ Avoid
expect(element).toBeTruthy();
expect(element.disabled).toBe(true);
```

## Tools Reference

- **@testing-library/react**: Render components, query elements
- **@testing-library/user-event**: Simulate user interactions (replaces fireEvent)
- **@testing-library/jest-dom**: Semantic assertions like `toBeInTheDocument()`
- **jest**: Test runner and mocking utilities

## Resources

See [BEST_PRACTICES.md](references/BEST_PRACTICES.md) for more detailed patterns and [COMMON_PITFALLS.md](references/COMMON_PITFALLS.md) for detailed explanations of mistakes to avoid.
