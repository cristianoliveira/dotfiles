# React Testing Best Practices

## Accessibility Testing

Always query by accessible attributes first:

```javascript
// ✅ Best - Users interact via roles and labels
screen.getByRole('button', { name: /submit/i })

// ⚠️ Okay - Users see labels
screen.getByLabelText('Email address')

// ❌ Avoid - Implementation detail
screen.getByTestId('email-input')
```

## Setup and Teardown

```javascript
describe('LoginForm', () => {
  let mockFetch;

  beforeEach(() => {
    mockFetch = jest.spyOn(global, 'fetch');
  });

  afterEach(() => {
    mockFetch.mockRestore();
  });

  it('logs in user when form is submitted', async () => {
    // test code
  });
});
```

## Testing User Events

```javascript
import userEvent from '@testing-library/user-event';

it('opens dropdown when clicked', async () => {
  const user = userEvent.setup();
  render(<Dropdown />);
  
  const trigger = screen.getByRole('button', { name: /options/i });
  await user.click(trigger);
  
  expect(screen.getByRole('menu')).toBeInTheDocument();
});
```

## Handling Promises and Timers

```javascript
// For API calls that resolve
it('displays data after fetch', async () => {
  jest.spyOn(global, 'fetch').mockResolvedValue({
    json: async () => ({ name: 'John' })
  });
  
  render(<UserData />);
  
  const name = await screen.findByText('John');
  expect(name).toBeInTheDocument();
});

// For setTimeout/setInterval
it('shows message after delay', async () => {
  jest.useFakeTimers();
  render(<DelayedMessage />);
  
  expect(screen.queryByText('Ready')).not.toBeInTheDocument();
  
  jest.advanceTimersByTime(1000);
  expect(screen.getByText('Ready')).toBeInTheDocument();
  
  jest.useRealTimers();
});
```

## Testing Error States

```javascript
it('displays error message when API fails', async () => {
  jest.spyOn(global, 'fetch').mockRejectedValue(new Error('Network error'));
  
  render(<DataFetch />);
  
  const error = await screen.findByText(/network error/i);
  expect(error).toBeInTheDocument();
});
```
