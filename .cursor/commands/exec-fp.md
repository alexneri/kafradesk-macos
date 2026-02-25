# Execute Feature Plan

Execute the feature plan attached to this chat or referenced in this message. Follow through all Discover-Define-Deliver phases and ensure every task is completed according to the acceptance criteria and quality gates defined in the plan.

**PREREQUISITE**: Before starting, read both user files:
1. **Preferences**: `~/Documents/DevContext/preferences.md` — Check for `source_code_access`, `local_repo_base_path`, and `code_investigation_depth`.
2. **Memory**: `~/Documents/DevContext/memory.md` — Check for learned patterns, repository knowledge, and user corrections relevant to this feature.

---

## Execution Strategy

### Phase 0: Load Context (sequential, before any code changes)

1. **Read preferences** from `~/Documents/DevContext/preferences.md`. Apply `agent_autonomy`, `code_investigation_depth`, and `verbosity` silently throughout execution.
2. **Read memory** from `~/Documents/DevContext/memory.md`. Apply any learned patterns or user corrections that affect this feature area.
3. **Read the feature plan** in full. Extract:
   - All acceptance criteria (these are the definition of done)
   - The complete file inventory (Files to Create + Files to Modify)
   - The implementation phases and their task breakdown
   - Any open questions or architectural decisions flagged in the plan
4. **Resolve open questions**: If the plan has unresolved open questions or flagged scope ambiguities, surface them to the user BEFORE writing any code. Do not proceed with ambiguous scope.
5. **Query context7** for library and framework guidance relevant to this feature (see **Context7 Protocol** below).

---

### Phase 1: Pre-Implementation Setup (sequential)

1. **Verify the file inventory**: Confirm every file listed in the plan's "Files to Create" and "Files to Modify" sections still exists (for modifications) or that the target directory exists (for new files). If a listed file is missing or a path has changed, flag it before proceeding.
2. **Confirm test conventions**: Identify the test framework, test file locations, and naming conventions from the existing codebase. If the plan specifies a test approach, verify it matches the codebase conventions.
3. **Confirm version locations**: Find every location where the version number appears in the codebase (see **Version Update Protocol** below). Document them before making any changes.

---

### Phase 2: Implementation (phased, per plan)

Execute each implementation phase from the feature plan in order. For each phase:

1. **Announce the phase** to the user: "Starting Phase [N]: [Phase Name]"
2. **Complete all tasks** in the phase before moving to the next
3. **Apply implementation principles** to every change (see below)
4. **Update the plan's tracking section** after each task is marked complete — do not batch tracking updates for the end
5. **Run a self-check** before moving to the next phase:
   - Does the code compile / type-check without errors?
   - Do existing tests still pass for the affected modules?
   - Does each changed function stay within 60 lines?
   - Are all return values checked?

**If `agent_autonomy` is `confirm_phases`**: Present a phase completion summary to the user and wait for confirmation before starting the next phase.

**If `agent_autonomy` is `confirm_all`**: Present each task result and wait for approval before proceeding.

**If `agent_autonomy` is `autonomous`**: Execute all phases without interruption; present the full summary at the end.

---

### Phase 3: Validation Gate (sequential, BLOCKING before close-out)

**Do NOT proceed to Phase 4 until all items pass.**

#### Acceptance Criteria Check
- [ ] Every acceptance criterion from the plan is met — verify each one explicitly, do not assume
- [ ] Any criterion that cannot be verified programmatically is flagged for user confirmation

#### Code Quality Check
- [ ] All new functions are ≤60 lines (NASA Power of 10, Rule 4)
- [ ] All return values are checked (Rule 7)
- [ ] All inputs are validated at entry points (Rule 7)
- [ ] Zero new linter/type-checker warnings introduced
- [ ] No dynamic allocation added outside initialization paths (Rule 3)

#### Test Check
- [ ] Unit tests written for all new functions/modules
- [ ] Existing tests still pass (no regressions)
- [ ] Edge cases identified in the plan are covered by tests

#### Version Check
- [ ] Version incremented in every location listed in the **Version Update Protocol**
- [ ] `--version` flag (or equivalent) returns the new version
- [ ] Version is consistent across all locations (package.json, changelog, manifest, etc.)

**If any check FAILS**: Fix the issue before proceeding. Do not mark the task complete and move on.

---

### Phase 4: Close-Out (sequential)

1. **Update the feature plan tracking section**:
   - Move all completed tasks to "Completed ✅"
   - Update "Implementation Status" table with 100% progress
   - Set document Status to `Complete`
   - Update "Last Updated" date
2. **Write to memory** (`~/Documents/DevContext/memory.md`):
   - Add the completed feature to "Completed Features": `[TICKET-ID]: [Brief description], completed [date], branch [name]`
   - Append any new repository/module knowledge discovered during implementation to "Repository Knowledge"
   - Append any architectural patterns learned to "Learned Patterns"
   - Append any corrections made during implementation to "User Corrections"
3. **Present the completion summary** to the user:

```markdown
## Execution Complete: [TICKET-ID]

### What was implemented
- [File created/modified]: [Brief description of change]
- [File created/modified]: [Brief description of change]

### Acceptance criteria
| Criterion | Status |
|-----------|--------|
| [Criterion 1] | ✅ Met |
| [Criterion 2] | ✅ Met |

### Version
- Previous: [old version]
- New: [new version]
- Updated in: [list of files]

### Tests
- New tests: [count]
- All existing tests: ✅ Passing

### Open items (if any)
- [Any follow-up tasks, known limitations, or technical debt introduced]
```

---

## Context7 Protocol

**When to query**: Phase 0, before writing any code.

**How to query**: Derive search terms from the feature plan's technical discovery section and the implementation files involved. Be specific.

```
Examples:

Feature involves TypeScript error handling:
→ Search context7: "TypeScript Result type error handling patterns"
→ Search context7: "TypeScript never throw async patterns"

Feature involves Node.js file system operations:
→ Search context7: "Node.js fs promises best practices"
→ Search context7: "Node.js stream error handling"

Feature involves terminal/CLI output:
→ Search context7: "chalk terminal color best practices"
→ Search context7: "Node.js process stdout TTY detection"
```

**What to do with results**:
- Apply recommended patterns directly in implementation
- Flag any anti-patterns found in existing code (note in plan but do NOT fix unrelated code)
- If context7 returns nothing relevant, note it and proceed with Agent 3 patterns from the feature plan

**What NOT to do**:
- Do not search context7 for generic terms ("best practices") — always include the library/framework name and specific operation
- Do not apply context7 recommendations to code outside the feature's scope

---

## Version Update Protocol

Version numbers appear in multiple locations. Before making changes, find ALL of them:

```bash
# Find version declarations
grep -r "\"version\":" package.json
grep -r "version = " --include="*.ts" --include="*.js" --include="*.py"
grep -r "VERSION" --include="*.ts" --include="*.js" --include="*.py" -l

# Find changelog or release notes
find . -name "CHANGELOG*" -o -name "CHANGES*" -o -name "HISTORY*"

# Verify --version output
node . --version   # or: python -m app --version, ./app --version, etc.
```

**Standard locations to check** (adjust for project type):
- `package.json` → `"version"` field
- `package-lock.json` → `"version"` field (update via `npm version`, not manually)
- Source constants file (e.g., `src/version.ts`, `src/constants.ts`)
- Changelog or release notes file
- Any `--version` flag handler in the CLI entry point

**CRITICAL**: After updating, run `[app] --version` (or equivalent) to verify the output matches. The `--version` flag output sometimes reads from a different location than `package.json`. Verify both match.

---

## Implementation Principles

### Domain-Driven Design (DDD)
- Identify and respect bounded contexts — do not reach across domain boundaries
- Use ubiquitous language from the domain in all new names (variables, functions, types, files)
- Model entities, value objects, aggregates, and domain events appropriately
- Keep domain logic separate from infrastructure concerns
- Apply repository patterns for data access

### NASA Power of 10 Rules
1. **Straight-line logic only**: Use `if/else`, `switch`, bounded loops. No `goto`, `setjmp/longjmp`, or recursion
2. **Bound every loop**: Hard upper limit provable at compile time or via assertion
3. **Freeze the heap**: Dynamic allocation only at startup, never afterward
4. **One-page functions**: ≤60 lines max per function
5. **Assert relentlessly**: ≥2 meaningful assertions per function
6. **Min-scope data**: Declare variables in the narrowest block needed
7. **Handshake on every call**: Caller checks every non-void return; callee validates all inputs
8. **Tame the preprocessor**: Limit to `#include` and simple macros
9. **Pointers on a leash**: At most one level of indirection, no function pointers
10. **Zero-warning policy**: All warnings enabled; ship only when build is clean

### Language Best Practices
- Follow the style guide already in use in the project (check `.eslintrc`, `pyproject.toml`, etc.)
- Use proper type annotations — no `any` in TypeScript without explicit justification
- Implement comprehensive error handling using the pattern already established in the codebase
- Write self-documenting code; comments explain WHY, not WHAT
- Apply SOLID principles where applicable

---

## Constraints

- Follow the feature plan precisely — do not deviate from the scope, file inventory, or architecture decisions in the plan
- If you discover a reason to deviate (e.g., the plan's file path is wrong, the architecture decision won't work), stop and explain why before making the change
- Do not refactor code outside the feature's scope, even if you notice issues
- Do not add dependencies not listed in the plan without asking the user first
- Update the plan's tracking section as tasks complete — do not leave it stale
