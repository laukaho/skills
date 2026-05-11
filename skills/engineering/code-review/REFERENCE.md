# Code Review Reference

## Severity Levels

- **[CRITICAL]** - Bugs, security vulnerabilities, data loss risks. Must fix before merge.
- **[WARNING]** - Code smells, maintainability issues, performance concerns. Should fix.
- **[SUGGESTION]** - Style nitpicks, minor improvements, alternative approaches. Optional.

## Bug Detection Checklist

### Logic Errors
- [ ] Off-by-one errors in loops and array access
- [ ] Integer overflow/underflow
- [ ] Race conditions in concurrent code
- [ ] Deadlocks and starvation
- [ ] Incorrect boolean logic (De Morgan's law violations)
- [ ] Time-of-check to time-of-use (TOCTOU) issues

### Error Handling
- [ ] Swallowed exceptions (empty catch blocks)
- [ ] Missing error return value checks
- [ ] Incorrect exception types
- [ ] Resource leaks in error paths
- [ ] Failures don't rollback state changes

### Security
- [ ] Unvalidated user input
- [ ] Missing authorization checks
- [ ] Sensitive data in logs
- [ ] Insecure cryptographic practices
- [ ] Path traversal vulnerabilities
- [ ] CORS misconfigurations

### Resource Management
- [ ] Unclosed file handles
- [ ] Unreleased database connections
- [ ] Memory leaks in long-running processes
- [ ] Unbounded buffers/queues
- [ ] Missing cancellation/timeout logic

## Code Smell Checklist

### Complexity
- [ ] Functions > 50 lines
- [ ] Cyclomatic complexity > 10
- [ ] Nested conditionals > 3 levels
- [ ] Boolean parameters
- [ ] Flag arguments controlling behavior

### Coupling & Cohesion
- [ ] Feature envy (methods using other objects more than own)
- [ ] Inappropriate intimacy (classes knowing too much about each other)
- [ ] Shotgun surgery (changes require many small edits)
- [ ] Middle man (delegating without adding value)

### Duplication
- [ ] Copy-pasted code blocks
- [ ] Similar conditional structures
- [ ] Parallel inheritance hierarchies
- [ ] Same algorithms with different data

### Data & Types
- [ ] Primitive obsession (using strings/ints instead of types)
- [ ] Data clumps (groups of variables passed together)
- [ ] Refused bequest (subclass ignoring inherited behavior)
- [ ] Switch statements on type (missing polymorphism)

## API Design Checklist

### Usability
- [ ] Self-documenting names (no need to read implementation)
- [ ] Consistent naming conventions
- [ ] Predictable parameter ordering
- [ ] Sensible defaults
- [ ] Fluent/builder interfaces where appropriate

### Robustness
- [ ] Input validation at boundaries
- [ ] Clear error messages (what went wrong, how to fix)
- [ ] Stable error types (caller can handle programmatically)
- [ ] No silent failures
- [ ] Graceful degradation

### Evolution
- [ ] Backward compatible changes
- [ ] Deprecation strategy
- [ ] Versioning if needed
- [ ] Minimal surface area (only expose what's needed)

## Performance Checklist

### Algorithms
- [ ] O(n²) or worse in loops over large collections
- [ ] Repeated lookups instead of caching
- [ ] Unnecessary sorting
- [ ] String concatenation in loops
- [ ] Converting collections unnecessarily

### I/O & Network
- [ ] Synchronous I/O in async contexts
- [ ] N+1 queries
- [ ] Missing pagination on large datasets
- [ ] Unnecessary network round trips
- [ ] Loading large files into memory

### Memory
- [ ] Large object allocations in hot paths
- [ ] Capturing closures with large scope
- [ ] Memory churn (lots of short-lived objects)
- [ ] Missing object pooling for heavy resources
- [ ] Incorrect buffer sizes

## Style Guide References

### C++ - [Google Style Guide](https://google.github.io/styleguide/cppguide.html)
Key sections:
- Naming (CamelCase for types, snake_case for variables)
- Header file organization
- Smart pointers over raw pointers
- Avoid exceptions

### Python - [Google Style Guide](https://google.github.io/styleguide/pyguide.html)
Key sections:
- PEP 8 compliance with Google amendments
- Import ordering (standard, third-party, local)
- Type hints required
- Docstring format

### C# - [Google Style Guide](https://google.github.io/styleguide/csharp-style.html)
Key sections:
- PascalCase for public members
- camelCase for private fields
- Braces always required
- var usage guidelines

### TypeScript - [Google Style Guide](https://google.github.io/styleguide/tsguide.html)
Key sections:
- Prefer interfaces over types
- Explicit return types on exports
- No any usage
- Null vs undefined consistency

## Architecture Review Checklist

### SOLID Principles
- [ ] Single Responsibility: Class/module has one reason to change
- [ ] Open/Closed: Extend behavior without modifying existing code
- [ ] Liskov Substitution: Subtypes fully substitutable
- [ ] Interface Segregation: Clients don't depend on unused methods
- [ ] Dependency Inversion: Depend on abstractions

### Design Patterns
- [ ] Appropriate use of patterns (not forced)
- [ ] Consistent pattern application
- [ ] Pattern intent matches implementation

### Testability
- [ ] Dependencies injectable
- [ ] Side effects isolated
- [ ] Pure functions where possible
- [ ] Test data easy to construct

## Review Etiquette

1. **Assume good intent** - The author wants to produce good code
2. **Explain why** - Don't just say "do X", explain the benefit
3. **Distinguish required vs optional** - Use severity levels clearly
4. **Offer alternatives** - "Consider Y instead of X because..."
5. **Praise good practices** - Highlight what was done well
6. **Focus on code, not coder** - "This approach has a race condition" not "You missed a race condition"