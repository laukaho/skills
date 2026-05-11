---
name: code-review
description: Generate comprehensive PR reviews covering performance, style, and architecture analysis. Use when user asks to review code, PR review, code review, check for bugs, analyze code smells, evaluate API design, or mentions pull request feedback.
---

# Code Review

## Quick start

1. Identify the language(s) in the PR
2. Run the appropriate review workflow below
3. Format findings as actionable review comments
4. Categorize each issue by severity: [CRITICAL], [WARNING], [SUGGESTION]

## Workflows

### Bug & Logic Review
- Check boundary conditions and off-by-one errors
- Verify error handling paths (null checks, exceptions)
- Validate resource cleanup (memory, file handles, connections)
- Review concurrency and threading issues
- Check for injection vulnerabilities (SQL, XSS, command)
- Verify authentication/authorization logic

### Code Smell Review
- Look for duplicated code (DRY violations)
- Check function length and complexity
- Identify magic numbers and hardcoded values
- Review class coupling and cohesion
- Flag commented-out code and TODOs without tickets
- Check for primitive obsession

### API Design Review
- Verify consistency with existing API patterns
- Check parameter validation and defaults
- Review error response formats
- Assess naming clarity and predictability
- Check for breaking changes
- Evaluate discoverability and documentation

### Performance Review
- Identify algorithmic complexity issues
- Check for N+1 queries or unnecessary loops
- Review memory allocations in hot paths
- Assess caching opportunities
- Check synchronous I/O in async contexts
- Look for resource leaks

### Style Review
- Apply language-specific Google style guide:
  - [C++](https://google.github.io/styleguide/cppguide.html)
  - [Python](https://google.github.io/styleguide/pyguide.html)
  - [C#](https://google.github.io/styleguide/csharp-style.html)
  - [TypeScript](https://google.github.io/styleguide/tsguide.html)
- Check naming conventions
- Verify formatting consistency
- Review import/organization order

### Architecture Review
- Assess separation of concerns
- Check dependency direction and coupling
- Review abstraction levels
- Evaluate testability
- Verify adherence to established patterns
- Check for over-engineering

## Output format

```
### [File:path/to/file]
**[SEVERITY]** Brief issue title
- **Line(s):** X-Y
- **Issue:** Description
- **Suggestion:** Concrete fix with code example
- **Reference:** Link or guide section
```

## Advanced features

See [REFERENCE.md](REFERENCE.md) for detailed checklists and [EXAMPLES.md](EXAMPLES.md) for sample reviews.