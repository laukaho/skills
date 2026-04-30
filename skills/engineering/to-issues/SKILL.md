---
description: Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices. Outputs to GitHub issues (default) or local markdown files. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
metadata:
    github-path: skills/engineering/to-issues
    github-ref: refs/heads/main
    github-repo: https://github.com/mattpocock/skills
    github-tree-sha: 2122925a2ea2d4dc0db572134c95199a6397a928
name: to-issues
---
# To Issues

Break a plan into independently-grabbable issues using vertical slices (tracer bullets).

## Mode Detection

Before proceeding, determine the output mode:

1. **Check if mode was already established in this conversation.** If the user has already answered "local" or "github" in a previous turn, use that mode without asking again.

2. **If this is the first time in this conversation:** Ask the user:
   
   > "Do you want to save issues as local files or GitHub issues? Reply 'local' or 'github'."

   Remember their answer for the rest of this conversation. Do NOT write any files to disk.

3. **If the user explicitly asks to change mode** (e.g. "switch to local mode" or "use github instead"), update your memory for this conversation and use the new mode going forward.

**Modes:**
- **Local mode**: Create markdown files in `./issues/open/` (format: `###-<kebab-case-title>.md`). Ensure the directory exists first.
- **GitHub mode** (default): Create GitHub issues via `gh issue create`

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a GitHub issue number or URL as an argument, fetch it with `gh issue view <number>` (with comments).

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Before exploring, follow [../grill-with-docs/DOMAIN-AWARENESS.md](../grill-with-docs/DOMAIN-AWARENESS.md). Issue titles and descriptions should use the project's `CONTEXT.md` vocabulary.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Create issues

#### If GitHub mode (default)

For each approved slice, create a GitHub issue using `gh issue create`. Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

<github-issue-template>
## Parent

#<parent-issue-number> (if the source was a GitHub issue, otherwise omit this section)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by #<issue-number> (if any)

Or "None - can start immediately" if no blockers.
</github-issue-template>

#### If Local mode

For each approved slice, create a markdown file in `./issues/open/` using the filename format `###-<kebab-case-title>.md` (use 3-digit numbers with leading zeros: `001`, `002`, etc.). Use the issue body template below.

Ensure the directory exists first.

Create issues in dependency order (blockers first) so you can reference real filenames in the "Blocked by" field.

<local-issue-template>
# <Issue Title>

Parent PRD: <parent-prd-filename> (if applicable)

Blocked by: #<issue-number-or-filename> (if any)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
</local-issue-template>

Do NOT close or modify any parent issue.
