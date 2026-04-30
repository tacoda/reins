Audit this project against the standards defined in its harness, and report violations.

This command is **read-only**. It produces a findings report and stops. The user picks what to address; fixes are separate work that follows the change approval flow in `CLAUDE.md`.

## Steps

1. **Inventory active rules.** List the files under `.claude/rules/` and read each one — these are the standards. Also load `CLAUDE.md` for project-specific conventions referenced as "Project-Specific Notes" or "Project-Specific Patterns".

2. **Set scope.** Default to the full codebase. The user may pass a path argument to narrow scope, in which case audit only that subtree.

3. **Run guardrails first.** Execute the project's automated checks:
   ```
   bundle exec rubocop
   bundle exec rspec
   bundle exec rake build
   ```
   Failures here are **Critical**. If the build is broken or tests fail, report that as the first finding and continue the rest of the audit so the user gets one comprehensive report.

4. **Audit per rule file.** For each rule, walk the in-scope code looking for violations. Examples (not exhaustive — read the actual rule files for the authoritative list):

   - **`design-principles.md`** — functions over ~30 lines or with more than three parameters; commented-out code; duplicated logic on its third or later occurrence; shallow modules with complex interfaces; type-branching where polymorphism would fit; speculative generality (unused parameters, unused config knobs); anemic data classes with no behavior.
   - **`tests.md`** — tests that mock internal collaborators; assertions on exact error message strings; tests using `sleep()`; tests that depend on each other's execution order; tests that exercise private methods or internal state.
   - **`security.md`** — hardcoded secrets, tokens, or credentials in source; string concatenation into queries, shell commands, or file paths; routes lacking auth middleware; PII or sensitive fields in logs, error messages, or response shapes; unpinned dependencies.
   - **`commits.md`** (audit the last ~20 commits with `git log --oneline -20`) — non-conventional subjects; co-author lines; AI-attribution lines.

5. **Categorize each finding.**
   - **Critical** — security, broken build, broken tests
   - **High** — correctness or safety issues that aren't immediately exploitable
   - **Medium** — design or clarity issues that hurt readability or maintainability
   - **Low** — style nits

6. **Report as a single markdown table.**

   | Severity | Rule | File:Line | Finding | Suggested fix |
   |---|---|---|---|---|

   Sort by severity (Critical → Low). Within a severity, group by rule.

7. **Stop.** Do not modify files. Present the table and ask the user which findings to address. Each fix is a separate change that goes through the project's change approval flow.

## Rules for this command

- **Read-only.** Never edit, delete, or move files. Never run anything that mutates state (no migrations, no fixers, no `--write` modes of linters).
- **Cite every finding** with `path/to/file.rb:42` so the user can jump straight to the code.
- **Distinguish violations from judgment calls.** A violation is when a rule is clearly broken. A judgment call is debatable. Mark judgment calls as such in the Finding column (e.g., "Judgment call: ..."). The user should be able to dismiss them quickly.
- **Do not invent rules.** If a piece of code is ugly but no rule prohibits it, omit it — or note it as a judgment call with the rule-file caveat.
- **One pass per rule file.** Read each rule once, scan for it, move on. Do not re-read rules mid-audit.
- **Be honest about coverage.** If a rule mentions a pattern you cannot mechanically detect (e.g., "names reveal intent"), say so in a final "Coverage notes" section rather than pretending to have audited it.
