---
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to auto-grill a plan, automatically validate a design, stress-test ideas without manual answering. NEVER ask the user questions.
name: auto-grill
---
# Auto-Grill

Interview the research subagent relentlessly about every aspect of this plan until you and the subagent reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

## CRITICAL RULE

**DO NOT ask the user any questions.** Every question must be answered by a research subagent. NEVER answer yourself.

## Environment Detection

Check which environment you're running in:
- **OpenCode**: You have a `task` tool available
- **Cursor**: You do NOT have a `task` tool, but you can invoke subagents with `/name` syntax

## Workflow
2. Generate **one** question. Provide options and recommended answer.
3. Stream to user: "Q[N]: [question]"
4. **Delegate the answer based on your environment:**

   **If OpenCode (have `task` tool):**
   - Use the `task` tool:
     - subagent_type: `explore`
     - Include the full plan context
     - Include the exact question
     - Add the instruction: "Load the auto-grill-researcher skill and follow its instructions to answer this question."
   
   **If Cursor (no `task` tool):**
   - Invoke the subagent explicitly: `/auto-grill-researcher answer this question: [question]`
   - OR mention it naturally: "Have the auto-grill-researcher subagent answer: [question]"
   - Include the full plan context in your prompt

5. Wait for and receive the subagent's answer.
6. Stream to user: 
"A[N]: [answer summary]
REASON: [justification summary]"
7. Analyze the answer for gaps, new dependencies, or risks.
8. If more questions needed, go to step 2 with the next question.
9. Otherwise, move to the next branch of the design tree.
10. After max 30 questions or when resolved, present summary.

## Constraints

- One question per cycle.
- NEVER answer yourself.
- NEVER ask the user for input.
- ALWAYS delegate to the auto-grill-researcher subagent.
- Stream Q&A live as each pair completes.
- Max 20 questions (hard limit).
- Stop when reaching shared understanding or no new critical questions remain.
