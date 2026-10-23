## Language — Which Natural Language to Write In

Which natural language new content is written in: code comments and docstrings,
commit messages, and documentation. Programming-language standards are not in
scope here (they live in the `ezai-*` skills).

### Decision order

1. **The repository's existing convention wins, per surface.** Observe it, do
   not assume it.
2. **No observable convention** (new repo, empty surface) — fall back on the
   context:
   - **internal / private** → **French**
   - **public / personal** → **English** (the default convention of online
     development)

The internal→French fallback is a **default, not an override**: a private
repository whose history is English stays English. Rule 1 always outranks it.

Private/internal context is indicated by a private repository, no public
registry publication, a proprietary or absent license, or corporate hosting.

### Observing the convention, per surface

| Surface                      | How to read it                                                        |
| ---------------------------- | --------------------------------------------------------------------- |
| Commit messages              | `git log --format=%B -20` — majority language, **subject _and_ body** |
| Code (comments, docstrings)  | the file being edited first, then its module, then the repo           |
| Documentation (README, docs) | the existing pages                                                    |

**Per surface, not per repo.** A repo with English commits and French
docstrings keeps both: align with what is already there, where you write.
Do not force uniformity across surfaces.

**Never retro-translate.** The rule governs **new** content only. Existing
history, docstrings and pages are not rewritten to match — unless the user
explicitly asks. Rewriting published commit messages is a history rewrite and
falls under the dangerous-operations rules of `security.md`.

**Squash-merge trap:** a squashed commit often has an English subject over a
fully French body (the body aggregates the branch's commits). Judging on
`git log --oneline` underestimates what is really there — read `%B`.
