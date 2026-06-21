# HLD Generator — Agent Prompt Template

Use this template as the starting point for a cloud agent session whenever you
want to manually trigger (or re-trigger) HLD generation from a specific merged
pull request.

---

## Reusable Prompt Template

Copy the block below, fill in the placeholders, and paste it into your cloud
agent (e.g. GitHub Copilot Coding Agent in IntelliJ or the web UI).

```
Inspect repository `<owner/repo>` on branch `<target-branch>`.

Task:
1. Find the most recently merged pull request into `<target-branch>` (or PR #<pr-number> if known).
2. Check whether the folder `<watched-folder>` was changed in that PR.
3. If the folder changed, identify all `.md` files inside `<watched-folder>` that were
   changed in the PR (exclude README.md).
4. For each changed requirement file, extract the architecture, components, data/control flow,
   dependencies, and key behaviours described in that Markdown file.
5. Generate (or update) one HLD file per changed requirement file at
   `<hld-output-dir>/<basename>-hld.md`, where `<basename>` is the requirement filename
   without extension. For example:
   - `<watched-folder>/payment-flow.md` → `<hld-output-dir>/payment-flow-hld.md`
   - `<watched-folder>/user-authentication.md` → `<hld-output-dir>/user-authentication-hld.md`
   Each HLD must include:
   - System overview
   - Main components (table preferred)
   - Data and control flow (Mermaid diagram preferred)
   - Assumptions
   - Open questions
6. If no relevant Markdown files are found in the folder, report that clearly and stop.
7. If the folder was not changed in the latest merged PR, report that clearly and stop.
8. Do not modify any application source code or unrelated files.
9. Open a pull request with the generated HLD files if any were created or updated.
```

---

## Placeholder Reference

| Placeholder          | Example value               | Description                              |
|----------------------|-----------------------------|------------------------------------------|
| `<owner/repo>`       | `sumncc/CopilotDemo`        | GitHub repository in `owner/repo` format |
| `<target-branch>`    | `main`                      | Branch that receives merged PRs          |
| `<pr-number>`        | `42`                        | Optional — pin to a specific PR          |
| `<watched-folder>`   | `doc/requirements`          | Folder to watch for Markdown changes     |
| `<hld-output-dir>`   | `doc/hld`                   | Directory where HLD files are written    |

---

## Optional Additions

Append any of these lines to the prompt above when needed:

- `"Use Mermaid diagrams wherever flow or relationships are described."`
- `"Keep the HLD concise — one page if possible."`
- `"Include line references back to the source Markdown files."`
- `"Follow the existing documentation style in the repository."`

---

## How the Automation Works

```
PR merged into <target-branch>
        │
        ▼
GitHub Actions: hld-generator.yml
        │
        ├─ Did <watched-folder> change? ──No──► Stop (no-op)
        │
        └─ Yes
              │
              ├─ Find *.md files changed in the PR (excluding README.md)
              │       │
              │       └─ None found? ──► Warning, stop
              │
              └─ Run .github/scripts/generate-hld.sh
                        │
                        └─ For each changed requirement file:
                                  │
                                  └─ Write <hld-output-dir>/<basename>-hld.md
                                            │
                                            └─ Upload as workflow artifact "hld-documents"
```

---

## Configuration

The workflow is configured via environment variables at the top of
`.github/workflows/hld-generator.yml`:

```yaml
env:
  TARGET_BRANCH:  main                 # branch that receives merged PRs
  WATCHED_FOLDER: doc/requirements     # folder to watch for Markdown changes
  HLD_OUTPUT_DIR: doc/hld             # directory where HLD files are written
```

Change these three values to adapt the workflow to any project or folder layout.
