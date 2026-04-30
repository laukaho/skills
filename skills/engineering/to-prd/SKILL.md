---
description: Turn the current conversation context into a PRD and save it as a GitHub issue or local markdown file. Use when user wants to create a PRD from the current context.
metadata:
    github-path: skills/engineering/to-prd
    github-ref: refs/heads/main
    github-repo: https://github.com/mattpocock/skills
    github-tree-sha: 0947764c280b6a0df423b1997a788b5faf0d399b
name: to-prd
---
This skill takes the current conversation context and codebase understanding and produces a PRD. Do NOT interview the user — just synthesize what you already know.

## Mode Detection

Before proceeding, determine the output mode:

1. **Check if mode was already established in this conversation.** If the user has already answered "local" or "github" in a previous turn, use that mode without asking again.

2. **If this is the first time in this conversation:** Ask the user:
   > "Do you want to save PRDs as local files or GitHub issues? Reply 'local' or 'github'."

   Remember their answer for the rest of this conversation. Do NOT write any files to disk.

3. **If the user explicitly asks to change mode** (e.g. "switch to local mode" or "use github instead"), update your memory for this conversation and use the new mode going forward.

**Modes:**
- **Local mode**: Save PRD to `./prd/<kebab-case-title>.md`. Ensure the directory exists first.
- **GitHub mode** (default): Create a GitHub issue via `gh issue create`

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Before exploring, follow [../grill-with-docs/DOMAIN-AWARENESS.md](../grill-with-docs/DOMAIN-AWARENESS.md). Use the project's `CONTEXT.md` vocabulary throughout the PRD.

2. Sketch out the major modules you will need to build or modify to complete the implementation. Actively look for opportunities to extract deep modules that can be tested in isolation.

A deep module (as opposed to a shallow module) is one which encapsulates a lot of functionality in a simple, testable interface which rarely changes.

Check with the user that these modules match their expectations. Check with the user which modules they want tests written for.

3. Write the PRD using the template below.

### If GitHub mode (default)
Submit the PRD as a GitHub issue using `gh issue create`.

### If Local mode
Save the PRD to `./prd/<kebab-case-title>.md`. Ensure the directory exists first.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
