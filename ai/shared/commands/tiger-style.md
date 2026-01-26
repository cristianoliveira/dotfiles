---
name: tiger-style
description: Apply Tiger Style - production assertions, design-first development, safety-critical practices, and fail-fast philosophy.
author: Cristian Oliveira
version: 0.1.0
---

# Tiger Style Methodology

Tiger Style is a software development philosophy that emphasizes reliability, correctness, and maintainability through rigorous engineering practices. It draws from safety-critical systems, design-first methodologies, and fail-fast operational patterns.

**Core Philosophy**: "Precision over flexibility, correctness before performance, auditability always." Slow down to speed up—invest in design and verification upfront to reduce technical debt and accelerate long-term delivery.

## Key Principles

### 1. Assertions in Production
- **Never disable assertions** in release builds—they are your safety net for "should never happen" conditions.
- Use language‑built‑in production assertions: Swift `precondition()`, Kotlin `require()`, Rust `assert!`, Zig `assert`, C++ Abseil `CHECK()`.
- Treat runtime assertions as executable documentation of invariants.
- **Rule**: Average at least two assertions per function (NASA Power of 10 Rule 5).

### 2. Design‑First Development
- **Write specifications before implementation**—complete all technical specs before writing any code (Z6 approach).
- Apply **Clean Architecture**, **Domain‑Driven Design**, or **Hexagonal Architecture** to enforce clear boundaries and dependency rules.
- Use collaborative design techniques: **Event Storming**, **User Story Mapping**, **Behaviour‑Driven Development**.
- **Design Stamina Hypothesis**: Upfront design investment pays off with faster delivery after the "design payoff line."

### 3. Safety‑Critical Programming Practices
- Follow **NASA Power of 10 Rules** for analyzable, reliable code:
  1. Simple control flow (no `goto`, recursion)
  2. Fixed loop bounds
  3. No dynamic memory allocation after initialization
  4. Small functions (~60 lines max)
  5. Assertion density ≥2 per function
  6. Minimal scope for data objects
  7. Check all return values and parameters
  8. Simple preprocessor usage
  9. Restricted pointers (≤1 level of dereference)
  10. Compile with zero warnings; daily static analysis.
- Adopt standards where applicable: **DO‑178C** (aerospace), **MISRA C/C++** (automotive/industrial), **IEC 62304** (medical devices).

### 4. Fail‑Fast Philosophy
- **Crash early, crash often**—better to stop immediately than continue in a corrupted state.
- Use **crash‑only software** design: microreboot to a known‑good state; same code paths for startup and recovery.
- Implement **circuit breakers** for external dependencies to prevent cascading failures.
- Embrace **Erlang/OTP "let it crash"** pattern: isolate failures, supervise restarts.
- Validate inputs at system boundaries and fail fast on invalid data.

## Practical Guidelines

### When to Apply Tiger Style
- **Financial systems** (transactions, ledgers)
- **Safety‑critical systems** (aerospace, medical, automotive)
- **High‑scale distributed systems** (cloud‑native, microservices)
- **Complex business domains** with long‑lived codebases
- **Any system where correctness outweighs rapid iteration**

### Code Examples

#### Production Assertions (Swift)
```swift
func processPayment(_ amount: Money, currency: Currency) -> Receipt {
    // Production assertion – crashes if violated
    precondition(amount > 0, "Payment amount must be positive")
    precondition(currency.isValid, "Invalid currency code")

    // Business logic
    let receipt = paymentGateway.charge(amount, currency)

    // Post‑condition
    assert(receipt.id != nil, "Receipt must have an ID")
    return receipt
}
```

#### Design‑First with Clean Architecture Layers
```
┌─────────────────────────────────────────┐
│         Frameworks & Drivers             │ ← Web, DB, External APIs
├─────────────────────────────────────────┤
│      Interface Adapters                 │ ← Controllers, Presenters
├─────────────────────────────────────────┤
│           Use Cases                      │ ← Application business rules
├─────────────────────────────────────────┤
│            Entities                     │ ← Core business rules
└─────────────────────────────────────────┘
```

#### NASA Power of 10 Style (C)
```c
void UpdateSensorReadings(SensorArray* sensors) {
    // Assertion density ≥2
    assert(sensors != NULL);
    assert(sensors->count <= MAX_SENSORS);

    // Fixed loop bound
    for (int i = 0; i < sensors->count; i++) {
        Sensor* s = &sensors->data[i];
        assert(s->id >= 0);

        Reading r = ReadSensor(s);
        assert(r.status == READING_OK);  // Check return value

        // Small function body (~60 lines max)
    }
}
```

#### Fail‑Fast Input Validation (Python)
```python
def create_order(order_data: dict) -> Order:
    # Validate everything before any side‑effects
    if not isinstance(order_data, dict):
        raise TypeError("order_data must be a dictionary")

    required = ['items', 'customer_id', 'total']
    for field in required:
        if field not in order_data:
            raise ValueError(f"Missing required field: {field}")

    if not order_data['items']:
        raise ValueError("Order must contain at least one item")

    for item in order_data['items']:
        if item.get('price', 0) < 0:
            raise ValueError("Item price cannot be negative")

    # Only proceed after all validation passes
    return Order.create(order_data)
```

#### Circuit Breaker Pattern (Pseudo‑code)
```java
public class CircuitBreaker {
    private State state = State.CLOSED;
    private int failures = 0;
    private static final int THRESHOLD = 5;

    public <T> T execute(Supplier<T> operation) {
        if (state == State.OPEN) {
            throw new CircuitOpenException("Service unavailable");
        }

        try {
            T result = operation.get();
            failures = 0;  // Reset on success
            return result;
        } catch (Exception e) {
            failures++;
            if (failures >= THRESHOLD) {
                state = State.OPEN;
                scheduleHalfOpen();
            }
            throw e;  // Fail fast
        }
    }
}
```

## Integration with Other Workflows

### Tiger Style + TDD
1. Write **specifications** (design) before tests.
2. Write **tests** that enforce invariants and edge cases.
3. Implement code to pass tests, adding **production assertions** for invariants.
4. Refactor while keeping tests green and assertions valid.

### Tiger Style + Clean Code
- Apply **SOLID principles** within a Clean Architecture.
- Keep functions small (Power of 10 Rule 4) and focused (SRP).
- Use assertions to document pre‑/post‑conditions (Design by Contract).
- Maintain zero warnings (Rule 10) and high test coverage.

### Tiger Style + CI/CD
- Run **static analysis** with zero warnings as a gate.
- Include **assertion‑aware testing**—ensure assertions fire correctly for invalid states.
- Use **circuit‑breaker metrics** in monitoring dashboards.
- Design for **crash‑only deployments** (microreboots, rolling restarts).

## Common Pitfalls & Trade‑offs

### Performance Overhead
- Production assertions add runtime cost. Balance safety vs. performance:
  - Use **debug assertions** for hot paths, **production assertions** for critical invariants.
  - Consider **compiler flags** to disable only the most expensive checks in release builds.

### User Experience
- Fail‑fast shows errors immediately. Combine with **graceful degradation** at UI layer.
- Provide **clear error messages** that explain what went wrong and suggest next steps.
