## Commits - Convention and Workflow

### Golden rule

Never mention an assistant, model, or tool in a commit message or pull request.
Never add a `Co-Authored-By:` trailer.

### Format

Use Conventional Commits:

```text
type(scope): description
```

- Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`,
  `build`, `ci`, `revert`.
- Use imperative mood, a lowercase start, no trailing period, and at most
  72 characters for the subject.
- Follow the repository language convention for commit subjects and bodies.

### Workflow

- Commit only when the user asks.
- Keep one logical change per commit.
- Create a branch before committing from `main` or `master`.
- Never bypass hooks with `--no-verify` unless the user explicitly asks.
- Never amend or force-push an already pushed commit unless the user explicitly
  asks.
- Review `git diff --cached` before committing.
- Use a POSIX shell and a heredoc for multi-line commit messages:

  ```bash
  git commit -F - <<'EOF'
  type(scope): description

  Optional body.
  EOF
  ```
