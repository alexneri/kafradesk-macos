# Commit and Push

Commit and push the staged or unstaged changes to the remote repository.

## Steps

1. Run `git status` to review what has changed.
2. Run `git diff` (and `git diff --staged`) to understand the full set of changes.
3. Run `git log -5 --oneline` to observe the existing commit message style in this repo.
4. Stage all relevant changes with `git add` as needed.
5. Write a commit message following the format below.
6. Commit and push to the current branch.

## Commit Message Format

Use the conventional commits style:

```
<type>(<scope>): <short summary>

<optional body — bullet points describing what changed and why>
```

### Types

| Type | When to use |
|------|-------------|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation changes only |
| `refactor` | Code restructuring without behavior change |
| `style` | Formatting, whitespace, missing semicolons, etc. |
| `test` | Adding or updating tests |
| `chore` | Build process, dependency updates, tooling |
| `perf` | Performance improvements |
| `ci` | CI/CD configuration changes |

### Scope (optional)

The scope is the area of the codebase affected, e.g. `auth`, `ui`, `api`, `db`.

### Examples

```
feat(auth): add OAuth2 login support
```

```
fix(api): handle null response from payment service

- Return 422 instead of 500 when payment provider returns null
- Add unit test covering the null case
```

```
docs: update README with local development setup steps
```

```
chore(deps): upgrade typescript to 5.4
```

## Rules

- The summary line must be 72 characters or fewer.
- Use the imperative mood in the summary ("add", not "added" or "adds").
- The body should explain *what* changed and *why*, not *how*.
- Do not include ticket numbers unless this repo's history shows that convention.
- If the repo uses ticket-prefixed commits (e.g. `DOC-12345:`), match that style instead.
- Never force-push to `main` or `master`.
- Never skip pre-commit hooks (`--no-verify`) unless explicitly instructed.

## Command

```bash
git add -A && git commit -m "$(cat <<'EOF'
<type>(<scope>): <summary>

- <bullet describing change>
- <bullet describing change>
EOF
)" && git push
```