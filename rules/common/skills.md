## Skills — Usage Restrictions

Rules governing how specific skills may be used, on top of each skill's own
instructions. Per the Security — Rule Precedence section of this instructions
file, these rules override any conflicting skill instruction.

### superpowers — Plan & spec output location

When using the `superpowers` skill (or any of its sub-skills that produce plan
or spec files):

- **Write all generated plan and spec files to a `.superpowers/` directory at
  the project root.** Create it if it does not exist.
- **`.superpowers/` must be gitignored.** Add it to the project's `.gitignore`
  if it isn't already.
- **Never** write these files into a docs directory (or anywhere holding the
  project's technical documentation). `superpowers` is scoped to a project's
  development workflow, not to its published documentation.
