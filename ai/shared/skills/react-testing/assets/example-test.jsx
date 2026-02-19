import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  it('displays form fields on render', () => {
    render(<LoginForm />);
    
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Password')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });

  it('submits the form with valid email and password', async () => {
    const user = userEvent.setup();
    const onSubmit = jest.fn();
    render(<LoginForm onSubmit={onSubmit} />);
    
    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: /sign in/i }));
    
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'john@example.com',
      password: 'password123'
    });
  });

  it('displays validation error when email is empty', async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    
    await user.click(screen.getByRole('button', { name: /sign in/i }));
    
    expect(screen.getByText('Email is required')).toBeInTheDocument();
  });

  it('disables submit button while request is in progress', async () => {
    const user = userEvent.setup();
    jest.spyOn(global, 'fetch').mockImplementation(
      () => new Promise(resolve => {
        setTimeout(() => resolve({ ok: true, json: async () => ({}) }), 100);
      })
    );
    
    render(<LoginForm />);
    
    const submitBtn = screen.getByRole('button', { name: /sign in/i });
    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(submitBtn);
    
    expect(submitBtn).toBeDisabled();
    
    await waitFor(() => {
      expect(submitBtn).not.toBeDisabled();
    });
  });
});
