---
name: semantic-commit
description: Split all working changes into logically isolated semantic commits following conventional commits format, excluding unfinished work. Use when user asks to commit changes, create semantic commits, split commits, or organize commits by change type.
---

# Semantic Commit

## Quick start

```
1. Run `git status` and `git diff` to see ALL changes
2. Identify and exclude unfinished work (WIP, TODOs, broken tests)
3. Stage only completed, related changes together
4. Craft a conventional commit message for each group
5. Commit each group separately
```

## Workflow

### Step 1: Review all changes

```bash
git status                  # Overview: staged, unstaged, untracked
git diff                    # All unstaged changes
git diff --staged           # Already staged changes
```

### Step 2: Identify and exclude unfinished work

Flag and skip anything that is:
- Marked with WIP, TODO, FIXME, or XXX comments
- Has failing tests or incomplete test coverage
- Contains placeholder code, mock data, or hardcoded values
- Part of an incomplete feature or broken build
- Has temporary debugging (console.log, debugger, etc.)
- Missing error handling or edge cases

**How to exclude:**
```bash
# Leave unfinished files unstaged
git add <finished-file-1> <finished-file-2>    # Stage only ready files

# Or stash unfinished work temporarily
git stash push -m "WIP: <description>" -- <unfinished-files>
```

### Step 3: Group related completed changes

From the remaining staged changes, identify logical groups that:
- Solve the same problem or implement the same feature
- Touch the same domain/component
- Are all tests for a specific change
- Are all documentation updates
- Are all refactors with no behavior change

### Step 4: Isolate and commit each group

If multiple groups are staged together, split them:

```bash
git reset HEAD <file-to-exclude>    # Unstage files not in current group
git add <file1> <file2>             # Re-stage only current group files

# Or use interactive staging for fine-grained control:
git add -p                          # Stage hunks selectively
```

### Step 5: Write conventional commit message

Analyze the diff content to determine:

| Type | Use when |
|------|----------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, semicolons, etc. |
| `refactor` | Code change with no behavior change |
| `test` | Adding or fixing tests |
| `chore` | Build, config, tooling changes |

```bash
git commit -m "type(scope): description"
```

**Examples:**
- `feat(auth): add OAuth2 login flow`
- `fix(api): handle null response in user endpoint`
- `test(checkout): add payment validation tests`
- `docs(readme): update setup instructions`

### Step 6: Repeat until done

```bash
git diff --staged --stat    # Verify remaining staged files
git status                  # Check for leftover changes
```

## Tips

- **Atomic commits**: Each commit should make sense on its own and not break the build
- **Scope**: Use a scope when the change affects a specific component (e.g., `feat(auth): add login`)
- **Breaking changes**: Add `!` after type/scope or `BREAKING CHANGE:` in body
- **Body**: Add a body for complex changes explaining "what" and "why"
- **When in doubt**: Ask the user to confirm groupings before committing
- **Preserve unfinished work**: Never commit WIP or broken code — leave it unstaged or stash it
