# Create Feature Plan

## Command Usage

Create a comprehensive feature plan for the ticket, issue, or feature description attached to this chat. This command analyzes the problem space, investigates the existing codebase, consults library best practices, and produces a detailed implementation plan.

**CRITICAL**: This command produces a PLAN, not implemented code. All acceptance criteria checkboxes MUST remain unchecked (`- [ ]`) in the output.

**PREREQUISITE**: Before starting, read both user files:
1. **Preferences**: `~/Documents/DevContext/preferences.md` — Check for `source_code_access`, `local_repo_base_path` or `github_org`, and `code_investigation_depth`. If the file is missing or relevant preferences are empty, ask the user before proceeding.
2. **Memory**: `~/Documents/DevContext/memory.md` — Check for relevant completed features, repository knowledge, and learned patterns that apply to this task.

---

## Planning Process

### Execution Strategy

This command uses a phased approach with parallel sub-agents for independent tasks. Follow this execution plan strictly.

#### Phase 0: Preferences and Memory (sequential, before anything else)

1. Read user preferences from `~/Documents/DevContext/preferences.md`. If the file is missing or relevant preferences are empty, ask the user before proceeding. If the file does not exist at all, create it using the template in the **Preferences File Format** section below, then ask the user to fill in the missing values.
2. Read agent memory from `~/Documents/DevContext/memory.md`. If the file does not exist, create it with the empty template in the **Memory File Format** section below.
3. **Apply behavioral preferences**:
   - `agent_autonomy` determines how much confirmation to ask for during execution
   - `code_investigation_depth` determines how exhaustive Agent 2's search should be (pass this setting explicitly to Agent 2's task description)
   - `verbosity` determines how much explanation to provide in the plan and during interaction
4. **Consult memory for this task**:
   - Check "Completed Features" — is this feature already planned or built? If so, inform the user.
   - Check "Repository Knowledge" — are there known repos, modules, or file paths for this feature area? If so, include them in Agent 2's search terms.
   - Check "Learned Patterns" — are there architectural or implementation patterns that apply? If so, apply them proactively.
   - Check "User Corrections" — are there corrections that affect how this command runs?

---

#### Phase 1: Investigation (parallel, up to 4 sub-agents)

Launch these sub-agents simultaneously. Each works independently and returns structured findings.

| Agent | Type | Model | Task | Returns |
|-------|------|-------|------|---------|
| **Agent 1: Issue Analyst** | `generalPurpose` | default | Read the ticket/issue/description, analyze comments and linked issues, identify scope, acceptance criteria, affected modules, and target users. If a Jira MCP is available, fetch the full ticket. | Ticket summary, linked issues, scope, affected modules, target users, key questions answered |
| **Agent 2: Code Investigator** | `explore` | default | Search the actual source code repository for existing implementations, patterns, entry points, configuration, and integration points related to the feature. See **Agent 2 Minimum Output Requirements** below. | List of relevant files with paths and line numbers, existing patterns, class/function/module names, config properties, search log |
| **Agent 3: Architecture Reviewer** | `explore` | default | Search the codebase for architectural patterns, test conventions, module boundaries, and integration points. Find similar features already implemented to use as structural templates. Identify where the new feature slots in. | Architectural patterns used, test file conventions, module/folder structure, integration points, template examples from existing features |
| **Agent 4: Library Scout** | `generalPurpose` | `fast` | Use context7 MCP to look up best practices, recommended patterns, and secure coding guidance for the libraries and frameworks relevant to this feature. Search for: the primary language/framework, any libraries directly involved, and security patterns if the feature touches auth or data handling. | Library recommendations, code patterns, version-specific guidance, security considerations |

**CRITICAL for sub-agent task descriptions**: Each agent has NO access to the parent conversation. You MUST include in each agent's task description:
- The feature name/ID and a summary of what is being built
- The `source_code_access` method and relevant paths/org from preferences
- Specific search terms derived from the ticket (feature names, module names, function names, config keys)
- What structured output format to return

**Example agent launch pattern:**
```
Agent 2 task: "Investigate source code for feature: clickable-report-path.
Feature description: Make report file path in terminal output clickable by displaying
the full path instead of truncating it.
Repository location: [local_repo_base_path]/dnr-docs-validate (or use GitHub MCP org: backbase-rnd).
Search for: BOX_WIDTH, reportPath, summary box rendering, chalk, terminal output formatting.
Look in: src/index.ts, src/reporter.ts, src/formatter.ts (or equivalent files).
Return: list of relevant files with line numbers, existing truncation logic,
constants used, and a search log of every search attempted."
```

**Agent 2 Minimum Output Requirements (BLOCKING)**:

Agent 2 MUST search actual source code, NOT documentation or README files only. If no source code is found, Agent 2 must document what was attempted and why it failed.

Agent 2 MUST return ALL of the following sections. If a section has no findings, Agent 2 must still include it with an explanation of what was searched and why nothing was found.

```
REQUIRED OUTPUT SECTIONS:

1. FILES SEARCHED (mandatory)
   - List every file or directory searched (e.g., "src/index.ts", "src/reporter/")
   - For each: access method used (local path or GitHub MCP), search terms used, whether results were found
   - If zero files found: list all search terms attempted and suggest alternative paths to try

2. RELEVANT CODE LOCATIONS (mandatory)
   - For each relevant file: exact path, key function/class/variable names, and line numbers
   - Existing logic that the new feature must integrate with or modify
   - If none found: state "No relevant code found" and explain what was searched

3. EXISTING PATTERNS (mandatory)
   - What design patterns are already in use (module structure, error handling, config loading)
   - How similar features are currently implemented (use as structural template)
   - Test conventions (file naming, test framework, assertion style)
   - If none found: state "No patterns identified" and explain what was searched

4. SEARCH LOG (mandatory)
   - Every search query/pattern attempted (grep patterns, file globs, GitHub searches)
   - Results count for each search
   - This log is used by Phase 1.5 to verify thoroughness
```

If Agent 2 returns output MISSING any of these four sections, Phase 1.5 will flag the investigation as incomplete and retry.

---

#### Phase 1.5: Findings Validation Gate (sequential, BLOCKING before Phase 2)

**CRITICAL: Do NOT proceed to Phase 2 until this gate passes.**

After all Phase 1 agents return, validate that Agent 2 (Code Investigator) produced substantive findings.

**Validation checks:**

1. **File coverage**: Did Agent 2 search actual source code files?
   - FAIL if: Agent 2 only read README, docs, or package.json
   - FAIL if: Agent 2 returned no file names from the `src/` directory (or equivalent)
   - FAIL if: Agent 2's "Files Searched" section is empty

2. **Code findings depth**: Did Agent 2 return specific technical findings?
   - PASS if: At least one function/class name with file path and line number
   - PASS if: At least one existing pattern identified (module structure, error handling, etc.)
   - PASS if: Agent 2 explicitly confirmed "no relevant code exists yet" with evidence (search log showing what was searched — appropriate for net-new features)
   - FAIL if: Agent 2 returned generic descriptions without file paths or function names

3. **Search log exists**: Did Agent 2 document what was searched?
   - FAIL if: No search log is present
   - FAIL if: Search log shows fewer than 3 distinct search attempts

**If validation FAILS:**

Launch a focused retry agent (Agent 2b):
```
Agent 2b task: "RETRY: The initial code investigation for [FEATURE-ID] was insufficient.
Previous search found: [summary of what Agent 2 returned].
Previous searches attempted: [from Agent 2's search log].

You MUST search the actual source code (not docs or README) using [local_repo_base_path OR github_org].

Try these strategies:
1. Glob for source files: src/**/*.ts, lib/**/*.js, **/*.py (use appropriate extension)
2. Search for the primary function/module name that will be affected
3. Search for config keys, constants, or error message strings related to the feature
4. Look for test files: **/*.test.ts, **/*.spec.ts — test file names often reveal structure
5. If GitHub MCP: search code in org:[github_org] for [feature keywords]

Return the 4 REQUIRED OUTPUT SECTIONS listed in the Agent 2 requirements."
```

**If validation PASSES:**

Proceed to Phase 2 with a note documenting code investigation quality:
- Number of files searched
- Number of functions/classes found
- Confidence level (High: multiple relevant files with line numbers; Medium: some findings; Low: confirmed net-new feature with evidence)

---

#### Phase 2: Synthesis (sequential, after Phase 1.5 validation passes)

After Phase 1.5 validation passes:

1. **Verify investigation coverage** before merging:
   - Confirm Agent 2 findings include specific file paths and function/class names
   - If code findings are thin (fewer than 2 relevant files found AND the feature modifies existing code), add a prominent `⚠️ CODE INVESTIGATION INCOMPLETE` warning in the plan's Technical Discovery section
   - Include a "Code Investigation Summary" subsection: files searched, functions/classes found, confidence level
2. **Merge findings** from all 4 agents (plus Agent 2b retry if it ran) into a unified discovery summary
3. **Determine scope** — check for scope creep signals:
   - Does the feature touch more than 3 unrelated modules? If so, flag as potentially multi-feature and ask the user before proceeding
   - Does the ticket description match the code investigation findings? If they diverge significantly, flag the discrepancy
4. **Apply the Discover-Define-Deliver framework** to assemble the plan
5. **Follow the template** at `~/Documents/DevContext/rules/featureplan-template.mdc`
6. **Apply implementation principles**: DDD, NASA Power of 10, language best practices (from exec-fp.md context — these inform what the plan should specify)
7. **Save the plan** to `[featureplan_output_dir from preferences]/[TICKET-ID]-featureplan-[YYYY-MM-DD].md`

---

#### Phase 3: Review (interactive, with user)

After the plan is saved:

1. **Present the summary** to the user (see **Post-Creation Review** section below)
2. **Ask confirmation questions** about scope, architecture decisions, and investigation depth
3. **Update the plan** based on user feedback if needed (including re-investigation if user flags gaps)
4. **Write to memory** once the user confirms the plan is ready

---

## Investigation Detail

### 1. Issue / Ticket Analysis (→ Phase 1, Agent 1: Issue Analyst)

**Review the ticket thoroughly:**
- Read the full description and acceptance criteria
- Analyze comments for scope changes, SME clarifications, or additional context
- Identify linked issues, parent epics, or blocking tasks
- Determine the type of change: net-new feature, enhancement to existing feature, bug fix, refactor
- Identify affected modules, services, or user-facing surfaces
- Note any explicit constraints (must not break X, must work with Y, performance target, etc.)

**Key questions to answer:**
- What problem is being solved, and for whom?
- What is the expected behavior after implementation?
- What must NOT change (regression boundaries)?
- Are there related open issues or follow-up work implied by this ticket?
- What is the definition of done?

**Document in plan:**
- Ticket ID, title, type (feature/enhancement/bugfix/refactor)
- Acceptance criteria (verbatim from ticket)
- Scope boundaries (in scope / out of scope)
- Any explicit technical constraints from the ticket

---

### 2. Source Code Investigation (→ Phase 1, Agent 2: Code Investigator)

**CRITICAL: Perform deep code analysis. Document ALL findings with specificity.**

**Locate relevant source files (use `local_repo_base_path` from preferences, or GitHub MCP if `source_code_access` is `github_mcp`):**
- Start with the primary entry point (e.g., `src/index.ts`, `main.py`, `app.js`)
- Follow the feature's data flow: input → processing → output
- Identify config loading, environment variable usage, and constants

**Search patterns to use (document what you find):**
```bash
# Find entry points and main modules
find src -name "*.ts" -o -name "*.js" -o -name "*.py" | head -30

# Find relevant function/class names
grep -r "featureKeyword" --include="*.ts" --include="*.js" -l

# Find config/constants
grep -r "CONSTANT_NAME\|configKey" --include="*.ts" --include="*.yaml"

# Find test files (reveals structure)
find . -name "*.test.*" -o -name "*.spec.*" | head -20

# Find similar existing features (use as template)
grep -r "similarFeatureName" --include="*.ts" -l
```

**For each relevant code location found, document:**
1. **File path**: Exact path from repo root
2. **Function/class name**: Exact name as it appears in code
3. **Line numbers**: Where the relevant logic starts and ends
4. **Purpose**: What this code does (one sentence)
5. **Integration point**: How the new feature will interact with this code (modify, extend, call, replace)

**For existing patterns, document:**
1. **Module structure**: How are modules organized? (feature-per-folder, layer-per-folder, etc.)
2. **Error handling style**: Exceptions, Result types, error codes, etc.
3. **Config loading**: Where and how configuration is read
4. **Test conventions**: Framework used, file naming, what gets mocked
5. **Type definitions**: Where interfaces/types are defined

**Analyze for:**
- Recent commits or PRs related to the feature area (if accessible)
- Any TODO/FIXME comments near the feature area
- Existing unit test coverage for affected code
- Integration or e2e test coverage
- Performance-sensitive paths the feature may affect

---

### 3. Architecture Review (→ Phase 1, Agent 3: Architecture Reviewer)

**Identify architectural patterns and structure:**
- How is the project structured? (monorepo, single package, multi-service, etc.)
- What is the primary module boundary this feature fits within?
- Is there a similar feature already implemented that can serve as a structural template?
- What are the natural extension points vs. areas that would require invasive changes?

**For each similar existing feature found, document:**
1. **Feature name**: What feature serves as the template
2. **File structure**: What files were created/modified for it
3. **Test approach**: How was it tested
4. **Integration pattern**: How it was wired into the main application

**Identify integration points:**
- Entry points that call the affected code
- Downstream consumers of the affected code's output
- Shared utilities or helpers the new feature should use
- Any event emitters, hooks, or middleware the feature should interact with

**Document test conventions:**
- Test file location and naming (e.g., `src/__tests__/`, `src/feature.test.ts`)
- Test framework and assertion library (Jest, Mocha, pytest, etc.)
- Mocking conventions (what gets mocked and how)
- Coverage expectations

---

### 4. Library and Pattern Research (→ Phase 1, Agent 4: Library Scout)

**Use context7 MCP to look up:**
- Primary framework/runtime best practices for the task at hand
- Security patterns if the feature involves authentication, input handling, or data access
- Performance guidance if the feature affects hot paths or output formatting
- Any library-specific patterns for the libraries directly used by the feature

**Specify search terms based on the feature:**
```
For a Node.js terminal output feature:
- Search: "chalk terminal output patterns"
- Search: "Node.js process.stdout best practices"
- Search: "ANSI escape codes terminal compatibility"

For a TypeScript config loading feature:
- Search: "TypeScript configuration loading patterns"
- Search: "dotenv best practices TypeScript"
```

**Document findings as:**
- Library name + version context
- Recommended pattern with brief code snippet
- What to avoid (anti-patterns flagged by the library docs)
- Security notes (if applicable)

If context7 returns nothing relevant, note what was searched and fall back to existing patterns found by Agent 3.

---

### 5. Scope Validation (→ Phase 2: Synthesis)

**Before assembling the plan, check for scope signals:**

| Signal | Action |
|--------|--------|
| Feature touches >3 unrelated modules | Flag as potential multi-feature; ask user if scope is intentional |
| Ticket description conflicts with code findings | Note the discrepancy; ask user to clarify before proceeding |
| "Simple" request requires architectural change | Escalate to user; explain the hidden complexity discovered |
| Net-new feature with no analogous code | Confirm with user which existing feature is the closest structural template |
| Breaking change to public API or config format | Ensure upgrade path or backward compatibility is part of the plan |

**Prioritization (apply in synthesis):**
- ✅ **PREFER:** Extending or modifying existing modules
- ⚠️ **CONSIDER:** Adding a new module under an existing subsystem
- ❌ **AVOID:** Creating a new top-level subsystem unless the ticket explicitly calls for it

---

### 6. Post-Creation Review and Confirmation (→ Phase 3: Review)

**CRITICAL: After saving the feature plan file, you MUST present a summary and ask confirmation questions BEFORE considering the task complete. Do NOT skip this step.**

#### Summary Presentation

Immediately after saving the plan, present a concise summary:

```markdown
## Feature Plan Summary: [TICKET-ID]

**Feature**: [One-line description]
**Type**: [Net-new | Enhancement | Bug Fix | Refactor]
**Confidence**: [High / Medium / Low] — based on code investigation depth

### Implementation Changes Planned
| Action | File/Module | Change Type | Rationale |
|--------|-------------|-------------|-----------|
| [Create/Modify/Delete] | [path] | [Add function / Extend class / Replace logic] | [Why] |

### Architecture Decisions Made
- [Decision 1 and the alternative that was rejected]
- [Decision 2 and the alternative that was rejected]

### Estimated Effort
- [Total hours or story points]
- [Phase breakdown]
```

#### Confirmation Questions

After presenting the summary, ask the following. Skip questions clearly not applicable, but err on the side of asking.

**Question 1: Scope**

> Based on my investigation, this feature affects: [list of modules/files].
>
> **Is this the right scope?**
> - _Should anything be excluded from this plan (saved for a follow-up ticket)?_
> - _Is there anything missing that should be included?_
>
> Currently planned: [in-scope items from the plan]

**Question 2: Architecture decision**

> I've chosen [approach X] over [approach Y] because [reason].
>
> **Does this architectural approach align with your intent?**
> - _[Approach X]: [brief description and trade-offs]_
> - _[Approach Y]: [brief description and trade-offs]_
>
> If you prefer a different approach, tell me and I'll revise the plan.

**Question 3: Existing code to reuse**

> I found [existing function/module/pattern] that the new feature could reuse or extend.
>
> **Should the implementation reuse this, or should it be implemented independently?**
> - _Reuse: [benefit] but [trade-off]_
> - _Independent: [benefit] but [trade-off]_

**Question 4: Test strategy**

> Based on existing test conventions, the plan calls for [unit tests / integration tests / e2e tests] using [framework].
>
> **Is this the right level of test coverage for this feature?**
> - _Consider: Is this a critical path? Does it involve external dependencies that should be mocked?_

**Question 5: Code investigation depth (always ask)**

> Here is a summary of the source code investigation:
>
> **Files searched**: [count and list key file paths from Agent 2 findings]
> **Relevant functions/classes found**: [count and list key names]
> **Existing patterns identified**: [list patterns found by Agent 3]
> **Investigation confidence**: [High/Medium/Low from Phase 1.5]
>
> **Is this technical depth sufficient for the feature plan?**
> - _If you expected specific files or modules to be found and they weren't, tell me and I'll re-investigate._
> - _If this is a net-new feature with no existing analogous code, "Low" confidence is expected and acceptable._

#### After User Responds

1. **Update the plan file** to reflect any changes from user feedback
2. **Note the revision** in the plan's document version (e.g., v1.0 → v1.1)
3. **Present the final summary** of what changed
4. **Confirm the plan is ready** for execution via `/exec-fp`
5. **Update memory file** (`~/Documents/DevContext/memory.md`):
   - Append new repository/module knowledge to "Repository Knowledge"
   - Append any user corrections to "User Corrections"
   - Append any new architectural patterns to "Learned Patterns"
   - Do NOT write to "Completed Features" yet — that happens when implementation is complete

---

## Plan Structure

### Use Template
**Follow:** `~/Documents/DevContext/rules/featureplan-template.mdc`

### Required Sections (all must be present)
1. Problem Statement (summary, background, user impact)
2. Discovery Research (current state, technical discovery, stakeholder insights)
3. Discovery Artifacts (relevant code locations, existing docs, external references)
4. Scope Definition (in scope, out of scope, assumptions, constraints)
5. Feature Objectives (with success metrics)
6. Information Architecture (content structure, files to create/modify)
7. Content Specifications (per section/component)
8. Cross-References and Navigation
9. Acceptance Criteria (ALL UNCHECKED — this is a plan, not a completed implementation)
10. Implementation Phases (with tasks, owners, status)
11. Dependencies (required resources, external dependencies)
12. Risk Assessment
13. Timeline Summary
14. Quality Gates
15. Delivery Checklist
16. Decision Log
17. Open Questions

### CRITICAL: Complete File Mapping

**The plan MUST include a complete file inventory:**

#### Files to Create
List ALL files that will be created:
- Source files (with full path from repo root)
- Test files (following existing test conventions)
- Config files (if any)
- Type definition files (if any)

**Example:**
```
Files to Create:
1. src/reporter/clickable-path.ts        — New module for path rendering logic
2. src/__tests__/clickable-path.test.ts  — Unit tests for new module
```

#### Files to Modify
List ALL files that will be modified:
- Entry points that need to call the new code
- Shared types or interfaces
- Config schemas
- Export indexes

**Example:**
```
Files to Modify:
1. src/index.ts              — Replace inline truncation logic with clickable-path module call
2. src/types.ts              — Add ClickablePathOptions interface
3. src/__tests__/index.test.ts — Update test expectations for non-truncated path output
```

#### Integration Map
For each new or modified file, specify:
- What calls it (upstream)
- What it calls (downstream)
- What shared state or config it reads

### Output Location
**Save plan to:** `[featureplan_output_dir from preferences]/[TICKET-ID]-featureplan-[YYYY-MM-DD].md`

**Example:** `~/Documents/DevContext/FEAT-123-featureplan-2026-02-19.md`

---

## Investigation Checklist (BLOCKING GATE — REQUIRED)

**This checklist is a BLOCKING requirement. Phase 1.5 validates the Source Code Investigation items. If items are incomplete, the plan CANNOT proceed to Phase 2 synthesis.**

### Agent 1: Issue Analyst (REQUIRED)
- [ ] Ticket ID, title, and type identified
- [ ] Acceptance criteria extracted (verbatim)
- [ ] Affected modules/services identified
- [ ] Scope boundaries defined (in/out of scope)
- [ ] Any explicit constraints documented

### Agent 2: Code Investigator (BLOCKING — Phase 1.5 validates these)
- [ ] Searched source directory (not just README/docs)
- [ ] Filed at least 3 distinct search attempts (documented in search log)
- [ ] Returned at least one of: relevant file path with line number, OR confirmed "net-new" with evidence
- [ ] Documented existing patterns (error handling, module structure, config loading)
- [ ] Documented test conventions (file location, framework, naming)

### Agent 3: Architecture Reviewer (REQUIRED)
- [ ] Module structure documented
- [ ] At least one analogous existing feature identified (or confirmed none exists)
- [ ] Integration points mapped (what calls what)
- [ ] Test file conventions documented

### Agent 4: Library Scout (REQUIRED)
- [ ] context7 queried with at least 2 relevant search terms
- [ ] Recommended patterns documented (or confirmed nothing relevant returned)
- [ ] Security considerations noted (if applicable)

---

## Behavioral Preferences Reference

### Preference Keys for This Command

| Key | Description | Values | Default |
|-----|-------------|--------|---------|
| `source_code_access` | How to access source code | `local`, `github_mcp`, `both` | — (ask if missing) |
| `local_repo_base_path` | Base directory where repos are cloned | `~/GitHub/`, `~/repos/` | — (ask if missing) |
| `github_org` | GitHub org for MCP searches | `backbase-rnd` | — (ask if missing) |
| `agent_autonomy` | Confirmation level | `confirm_all`, `confirm_phases`, `autonomous` | `confirm_phases` |
| `code_investigation_depth` | How deep Agent 2 searches | `shallow`, `standard`, `deep` | `standard` |
| `verbosity` | Explanation detail level | `concise`, `standard`, `detailed` | `standard` |
| `featureplan_output_dir` | Where to save plans | `~/Documents/DevContext/` | `~/Documents/DevContext/` |

**`agent_autonomy` values explained:**
- **`confirm_all`**: Confirm every step and edit before proceeding
- **`confirm_phases`**: Confirm at phase boundaries only (after Phase 1.5, after Phase 2 synthesis, during Phase 3 review)
- **`autonomous`**: Execute the full command and present the final plan — minimal interruptions

**`code_investigation_depth` values explained:**
- **`shallow`**: Read the ticket and top-level entry point only. Suitable for trivial changes with an obvious, localized edit.
- **`standard`**: Follow the Phase 1.5 validation gate as written. Search at least 3 relevant source files.
- **`deep`**: Exhaustive search. Read all modules in the affected subsystem, trace data flow end-to-end, include full search logs in the plan.

---

## Preferences File Format

If `~/Documents/DevContext/preferences.md` does not exist, create it with this template:

```markdown
# User Preferences for Feature Planning

## Source Code Access
- **source_code_access**: 
- **local_repo_base_path**: 
- **github_org**: 

## MCP and Tool Configuration (auto-detected)
<!-- These are auto-detected by the agent. Do not fill in manually unless overriding. -->
- **has_github_mcp**: 
- **has_github_cli**: 
- **has_jira_mcp**: 
- **has_context7_mcp**: 

## Agent Behavior
- **agent_autonomy**: confirm_phases
- **code_investigation_depth**: standard
- **verbosity**: standard

## Feature Planning Conventions
- **primary_language**: 
- **featureplan_output_dir**: ~/Documents/DevContext/
```

---

## Memory File Format

If `~/Documents/DevContext/memory.md` does not exist, create it with this template:

```markdown
# Agent Memory — Feature Planning

## Completed Features
<!-- Format: [TICKET-ID]: [Brief description], completed [date], branch [name] -->

## Learned Patterns
<!-- Format: **[Pattern name]**: [What to do] (learned from [ticket/context]) -->

## Repository Knowledge
<!-- Format: **[Feature/Module]**: [repo-path], [key files], [key functions] -->

## User Corrections
<!-- Format: [Date]: [What was corrected] → [What the correct behavior is] -->

## Open Architectural Decisions
<!-- Format: [Date]: [Decision pending], context: [what was found], options: [A vs B] -->
```

---

## Implementation Principles Reference

The plan must specify implementation guidance consistent with these principles (from `/exec-fp.md`):

### Domain-Driven Design
- Identify the bounded context this feature belongs to
- Use ubiquitous language from the domain in all names
- Keep domain logic separate from infrastructure concerns
- Apply repository patterns for data access where applicable

### NASA Power of 10 (for safety-critical or reliability-sensitive features)
The plan should flag if any of these constraints affect the implementation:
1. Straight-line logic only (no goto, no recursion)
2. Every loop must have a provable bound
3. No dynamic heap allocation after initialization
4. Functions ≤ 60 lines
5. ≥ 2 assertions per function
6. Variables declared in narrowest scope
7. Every return value checked; every input validated
8. Preprocessor limited to includes and simple macros
9. At most one level of pointer indirection
10. Zero-warning policy

### Language Best Practices
The plan should specify:
- Which style guide governs this codebase (e.g., Airbnb, PEP 8, Google)
- Linting/formatting tools and their configs
- Type annotation requirements
- Error handling conventions already in use

---

## Constraints

- Follow the feature plan template at `~/Documents/DevContext/rules/featureplan-template.mdc`
- Prioritize reusing existing functions before creating new ones
- Consider whether a simple update suffices before proposing a new module
- If the feature falls under an existing primary feature, extend it rather than creating a new top-level module — unless explicitly stated or it is genuinely a new primary capability
- All acceptance criteria checkboxes in the output plan MUST remain unchecked (`- [ ]`) — this is a plan, not a completed implementation
