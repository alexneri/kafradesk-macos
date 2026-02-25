# Review Pull Request

Review the specified PR as discussed in the chat or in this message. Always check the intent of the PR and the base code repository, and assess all changes against both. Perform a deep review including the related ticket, codebase conventions, and quality standards.

**PREREQUISITE**: Before starting, read both user files:
1. **Memory**: `~/Documents/DevContext/memory.md` — Check for learned patterns, known architectural decisions, and user corrections that apply to this codebase area.
2. **Preferences**: `~/Documents/DevContext/preferences.md` — Check for `source_code_access`, `local_repo_base_path`, and whether `has_github_cli` is set. Use GitHub CLI (`gh pr view [number]`, `gh pr diff [number]`) to fetch the PR diff and description if available.

**Context7**: Query context7 for any library or framework directly involved in the PR changes — use specific terms derived from the changed files, not generic terms. Use findings to validate whether the implementation follows recommended patterns.

**Output file**: Save findings to `~/Documents/DevContext/pr-review-[PR-number]-[YYYY-MM-DD].md` (example: `pr-review-42-2026-02-19.md`).

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
## Review Summary: PR #[number] — [PR Title]

### Verdict
[APPROVED | APPROVED WITH COMMENTS | CHANGES REQUIRED]

### Findings
| Severity | Count | Key Issues |
|----------|-------|------------|
| Critical | [n] | [brief description] |
| Major | [n] | [brief description] |
| Minor | [n] | [brief description] |

### PR Intent Alignment
[Does the implementation match the stated PR intent and linked ticket?]

### Top Recommendation
[The single most important thing to address before merging]
```

Then ask: **"Are there any areas you'd like me to investigate more deeply?"**

## Constraints

- Flag violations with severity: **Critical** (blocks merge), **Major** (should fix), **Minor** (nice to have)
- Provide specific file path and line number references for every finding
- Suggest concrete fixes, not just flagged problems
- Always assess changes against the PR's stated intent — do not flag correct deviations from the base as bugs
- Do not flag style issues as Critical unless they violate a hard rule (e.g., NASA Power of 10)
