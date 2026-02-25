# Root Cause Analysis & Surgical Bug Fix

Perform a comprehensive root cause analysis and implement a surgical fix for the bug or issue attached to this chat.

**PREREQUISITE**: Before starting, read both user files:
1. **Memory**: `~/Documents/DevContext/memory.md` — Check "Repository Knowledge" for known file locations relevant to this bug area, and "Learned Patterns" for any known patterns that may explain or relate to this issue.
2. **Preferences**: `~/Documents/DevContext/preferences.md` — Check for `source_code_access` and `local_repo_base_path`.

**Output file**: Save the RCA document to `~/Documents/DevContext/RCA-[brief-slug]-[YYYY-MM-DD].md` (example: `RCA-path-truncation-2026-02-19.md`).

After completing the fix: update any related feature plan with completed tasks and status, then increment the version numbers everywhere (see the Version Update Protocol in `exec-fp.md`).

## Analysis Protocol

### Phase 1: INVESTIGATE (Root Cause Analysis)

1. **Reproduce & Observe**
   - Understand the exact symptoms and failure conditions
   - Identify the expected vs. actual behavior
   - Note environmental context (versions, configurations, inputs)

2. **Trace the Execution Path**
   - Map the code flow from entry point to failure point
   - Identify all components, functions, and data transformations involved
   - Document the call stack and state changes at each step

3. **Isolate the Root Cause**
   - Use binary search approach to narrow down the problem location
   - Distinguish between the symptom and the actual root cause
   - Identify WHY the bug exists, not just WHERE it manifests
   - Check for related issues (is this a pattern or isolated incident?)

4. **Architecture Context**
   - Review the overall code architecture surrounding the bug
   - Understand design patterns and conventions already in use
   - Identify dependencies and potential ripple effects of any change

### Phase 2: PLAN (Fix Strategy)

1. **Research Best Practices**
   - Use context7 MCP to verify proper code patterns — search with specific terms derived from the bug location (e.g., "TypeScript async error handling" or "Node.js stream backpressure"), not generic terms
   - If context7 returns nothing relevant, document what was searched and fall back to existing codebase patterns
   - Check for secure coding patterns relevant to the fix
   - Review recommended approaches for similar issues

2. **Evaluate Fix Options**
   - List all possible fix approaches (minimum 2-3 alternatives)
   - Assess each option by:
     - Lines of code changed (fewer is better)
     - Scope of impact (narrower is better)
     - Risk of regression (lower is better)
     - Alignment with existing patterns (higher is better)

3. **Select Surgical Fix**
   - Choose the fix that addresses the ROOT CAUSE with MINIMAL changes
   - Avoid "forcing" desired outcomes (e.g., null checks that mask deeper issues)
   - Prefer fixing the source over patching the symptom
   - Ensure the fix follows existing code conventions

### Phase 3: IMPLEMENT (Surgical Execution)

1. **Precision Changes Only**
   - Change ONLY what is necessary to fix the root cause
   - Do NOT refactor surrounding code unless directly required
   - Do NOT add defensive code for unrelated edge cases
   - Do NOT change formatting or style of unrelated lines

2. **Validate the Fix**
   - Verify the fix addresses the root cause, not just the symptom
   - Confirm existing functionality remains intact
   - Check for any new edge cases introduced

3. **Document the Fix**
   - Explain WHY the bug occurred (root cause)
   - Explain WHY this fix was chosen over alternatives
   - Note any follow-up technical debt if applicable

## Surgical Fix Principles

**DO:**
- Fix at the source, not at the symptom
- Use existing abstractions and patterns
- Make the smallest change with the greatest impact
- Trust the existing architecture unless it IS the problem

**DO NOT:**
- Add null checks that mask deeper issues
- Wrap failures in try-catch without addressing cause
- Force expected outputs without fixing logic
- Refactor or "improve" unrelated code
- Add validation layers that duplicate existing checks
- Change code style or formatting beyond the fix scope

## Output Format

```markdown
# RCA: [Brief Issue Description]

## Bug Summary
- **Symptom**: [What is observed]
- **Expected**: [What should happen]
- **Impact**: [Severity and scope]

## Root Cause Analysis
- **Execution Path**: [Step-by-step trace]
- **Root Cause**: [The actual source of the bug]
- **Why It Occurred**: [Technical explanation]

## Fix Strategy
- **Option 1**: [Description] — [Pros/Cons]
- **Option 2**: [Description] — [Pros/Cons]
- **Selected**: [Which option and why]

## Implementation
- **Files Changed**: [List]
- **Lines Modified**: [Count]
- **Change Summary**: [Brief description]

## Verification
- **Root Cause Addressed**: [Yes/No + explanation]
- **Regression Risk**: [Assessment]
- **Follow-up Needed**: [If any]
```

## Post-Fix Memory Update

After the RCA document is saved and the fix is implemented, write to `~/Documents/DevContext/memory.md`:
- Append the root cause pattern to "Learned Patterns" if it represents a reusable insight (e.g., "**Off-by-one in box-width calculation**: When adding items to a fixed-width terminal box, account for padding on both sides")
- Append any newly discovered file/module locations to "Repository Knowledge"
- Append any user corrections made during this session to "User Corrections"

---

## Constraints

- Maximum impact with minimum code change
- Never force outcomes — fix root causes
- Always verify via context7 for pattern compliance (use specific search terms, not generic ones)
- Document the "why" behind both the bug and the fix
- Output file naming: `RCA-[brief-slug]-[YYYY-MM-DD].md` in `~/Documents/DevContext/`
