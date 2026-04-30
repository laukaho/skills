---
name: ralph
description: Orchestrate automated issue processing with AI agents (opencode or Cursor). Fetches unblocked child issues from a parent PRD and runs the configured AI agent to implement them, handling branching, commits, and status tracking. Use when user mentions "ralph", "process issues", "work through issues", or wants to automate implementation of PRD child issues. Supports both GitHub Issues and local markdown file workflows.
---

# Ralph

## Quick start

The shell scripts are bundled with this skill, located in the `scripts/` directory next to this SKILL.md file. Copy them to your repo or run them directly from the skill path.

**GitHub mode** (issues stored in GitHub):
```bash
./scripts/ralph.sh <parent-issue-number>
./scripts/ralph-loop.sh <parent-issue-number>
```

**Local mode** (issues stored as markdown files):
```bash
./scripts/ralph.sh <prd-file.md>
./scripts/ralph-loop.sh <prd-file.md>
```

## Workflows

### 1. Set up local mode

Create directories:
```bash
mkdir -p issues/{open,in-progress,done,failed}
mkdir -p prd
```

Create an issue file in `issues/open/`:
```markdown
# Fix login button

Parent PRD: prd/001-auth.md

Blocked by: #002

## Description
The login button is not clickable on mobile.
```

### 2. Run ralph

```bash
./scripts/ralph.sh prd/001-auth.md
```

Ralph will:
1. Create (or checkout) a PRD branch: `ralph/prd-<identifier>` from the current branch
2. Find the first unblocked open issue for that PRD
3. Move it to `issues/in-progress/`
4. Create an issue branch from the PRD branch: `ralph/<issue-name>`
5. Run the configured AI agent with the issue context
6. Merge the issue branch back into the PRD branch
7. Push the PRD branch and return to the original branch
8. Move issue to `issues/done/` or `issues/failed/`

For GitHub mode, ralph automatically creates the labels `ralph-in-progress`, `ralph-done`, and `ralph-failed` if they don't already exist in the repo.

### 3. Process all issues

```bash
./scripts/ralph-loop.sh prd/001-auth.md
```

Runs ralph continuously until no more unblocked issues remain.

### 4. Use Cursor instead of opencode

```bash
RALPH_AI_RUNNER=cursor ./scripts/ralph-loop.sh prd/001-auth.md
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_AI_RUNNER` | `opencode` | AI agent to use: `opencode` or `cursor` |
| `RALPH_ISSUES_DIR` | `./issues` | Root directory for local issues |
| `RALPH_PRD_DIR` | `./prd` | Directory for PRD files |

## Issue format

Local issues are markdown files with these conventions:

- **Title**: First `# ` heading
- **Parent PRD**: `Parent PRD: <filename>` anywhere in file
- **Blocked by**: `Blocked by: #001, #002` (optional)
- **Status**: Determined by which subdirectory the file is in

## Advanced features

- Auto-detects mode: local if `issues/open/` exists, GitHub otherwise
- Skips blocked issues until their dependencies are done
- Prevents duplicate branches (`ralph/<issue-name>`)
- Labels GitHub issues with `ralph-in-progress`, `ralph-done`, `ralph-failed` (auto-creates labels if missing)
- **Branching strategy**: Creates a PRD branch first (`ralph/prd-<identifier>`), then branches issues from it. Issue branches are merged back into the PRD branch after completion.
