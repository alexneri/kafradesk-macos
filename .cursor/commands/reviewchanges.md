# Review Code Changes

Review the current changes in this branch as discussed in the chat or in this message. Perform a deep review against the related ticket, codebase conventions, and quality standards.

**PREREQUISITE**: Before starting, read both user files:
1. **Memory**: `~/Documents/DevContext/memory.md` — Check for learned patterns, known architectural decisions, and user corrections that apply to this codebase area.
2. **Preferences**: `~/Documents/DevContext/preferences.md` — Check for `source_code_access` and `local_repo_base_path`.

**Context7**: Query context7 for any library or framework directly involved in the changes being reviewed — use specific terms (e.g., "chalk terminal output patterns", "TypeScript discriminated union best practices"), not generic terms. Use findings to validate whether the implementation follows recommended patterns.

**Output file**: Save findings to `~/Documents/DevContext/code-review-[branch-or-slug]-[YYYY-MM-DD].md` (example: `code-review-clickable-path-2026-02-19.md`).

## Review Criteria

### Code Best Practices
- Follows language-specific style guides and idioms
- Uses meaningful, intention-revealing names
- Functions are small, focused, and do one thing well
- Code is self-documenting with clear logic flow
- Proper error handling and edge case coverage
- No code duplication (DRY principle)
- SOLID principles applied where appropriate

### Secure Code Patterns
- Input validation at system boundaries
- No hardcoded secrets or credentials
- Proper authentication and authorization checks
- Protection against injection attacks (SQL, XSS, etc.)
- Secure data handling and encryption where needed
- Principle of least privilege applied
- No sensitive data in logs or error messages

### Domain-Driven Design (DDD)
- Bounded contexts are respected
- Ubiquitous language used consistently
- Entities, value objects, and aggregates modeled correctly
- Domain logic separated from infrastructure
- Repository patterns used for data access
- Domain events implemented where appropriate

### NASA Power of 10 Compliance
1. Straight-line logic only (no goto, recursion)
2. All loops have fixed upper bounds
3. No dynamic memory allocation after initialization
4. Functions ≤60 lines
5. ≥2 assertions per function
6. Variables declared in narrowest scope
7. All return values checked; all inputs validated
8. Preprocessor limited to includes and simple macros
9. Pointer use restricted (max one level of indirection)
10. Zero compiler warnings

### Testability
- Code is modular and loosely coupled
- Dependencies are injectable
- Pure functions preferred where possible
- Side effects are isolated and explicit
- Test coverage for critical paths
- Edge cases and error conditions tested
- Mocking/stubbing is straightforward

## Post-Review Summary

After saving the review file, present a concise summary to the user:

```markdown
## Review Summary: [Branch / Feature Name]

### Verdict
[APPROVED | APPROVED WITH COMMENTS | CHANGES REQUIRED]

### Findings
| Severity | Count | Key Issues |
|----------|-------|------------|
| Critical | [n] | [brief description] |
| Major | [n] | [brief description] |
| Minor | [n] | [brief description] |

### Feature Plan Alignment
[Does the implementation match the plan? Any deviations?]

### Top Recommendation
[The single most important thing to address before merging]
```

Then ask: **"Are there any areas you'd like me to investigate more deeply?"**

## Constraints

- Flag violations with severity: **Critical** (blocks merge), **Major** (should fix), **Minor** (nice to have)
- Provide specific file path and line number references for every finding
- Suggest concrete fixes, not just flagged problems
- Verify changes align with the feature plan and ticket requirements
- Do not flag style issues as Critical unless they violate a hard rule (e.g., NASA Power of 10)
