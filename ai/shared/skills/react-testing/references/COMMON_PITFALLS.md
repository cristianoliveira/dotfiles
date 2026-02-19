# Common React Testing Pitfalls

## 1. Testing Implementation Details

**Problem:** Testing the "how" instead of the "what"

```javascript
// ❌ Bad - Tests implementation
it('calls setUser with correct value', () => {
  const mockSetUser = jest.fn();
  // ...
  expect(mockSetUser).toHaveBeenCalledWith({ id: 1 });
});
```

**Solution:** Test user-visible behavior

```javascript
// ✅ Good - Tests outcome
it('displays user greeting after login', async () => {
  render(<LoginForm />);
  // ... user interaction
  expect(screen.getByText(/hello john/i)).toBeInTheDocument();
});
```

## 2. Mocking Everything

**Problem:** Over-mocking creates brittle tests

```javascript
// ❌ Bad - Too many mocks
jest.mock('../hooks/useUser');
jest.mock('../components/Avatar');
jest.mock('../utils/formatName');
```

**Solution:** Mock only external dependencies

```javascript
// ✅ Good - Mock only the API
jest.mock('../api/userService');
userService.getUser.mockResolvedValue({ name: 'John' });
```

## 3. Using fireEvent Instead of User Event

**Problem:** fireEvent doesn't simulate real browser behavior

```javascript
// ❌ Bad
fireEvent.click(button);
fireEvent.change(input, { target: { value: 'test' } });
```

**Solution:** Use @testing-library/user-event

```javascript
// ✅ Good
const user = userEvent.setup();
await user.click(button);
await user.type(input, 'test');
```

## 4. Not Wrapping Tests in act()

**Problem:** React warnings about state updates

```javascript
// ❌ Bad - Missing act()
it('updates state', () => {
  const { rerender } = render(<Component prop={1} />);
  rerender(<Component prop={2} />);
});
```

**Solution:** Use async utilities that wrap in act()

```javascript
// ✅ Good - waitFor handles act()
it('updates after async operation', async () => {
  render(<Component />);
  
  await waitFor(() => {
    expect(screen.getByText('Updated')).toBeInTheDocument();
  });
});
```

## 5. Hard-coded Delays

**Problem:** Tests are flaky and slow

```javascript
// ❌ Bad
it('loads data', async () => {
  render(<DataLoader />);
  await new Promise(r => setTimeout(r, 1000));
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});
```

**Solution:** Wait for specific elements

```javascript
// ✅ Good
it('loads data', async () => {
  render(<DataLoader />);
  const data = await screen.findByText('Loaded');
  expect(data).toBeInTheDocument();
});
```
