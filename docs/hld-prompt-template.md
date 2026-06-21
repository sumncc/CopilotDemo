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
3. If the folder changed, inspect all `.md` files inside `<watched-folder>`.
4. Extract the architecture, components, data/control flow, dependencies, and
   key behaviours described in those Markdown files.
5. Generate (or update) a High-Level Design document at `<hld-output-path>/<hld-output-file>`.
   The HLD must include:
   - System overview
   - Main components (table preferred)
   - Data and control flow (Mermaid diagram preferred)
   - Assumptions
   - Open questions
6. If no Markdown files are found in the folder, report that clearly and stop.
7. If the folder was not changed in the latest merged PR, report that clearly and stop.
8. Do not modify any application source code or unrelated files.
9. Open a pull request with the generated HLD if any file was created or updated.
```

---

## Placeholder Reference

| Placeholder          | Example value          | Description                              |
|----------------------|------------------------|------------------------------------------|
| `<owner/repo>`       | `sumncc/CopilotDemo`   | GitHub repository in `owner/repo` format |
| `<target-branch>`    | `main`                 | Branch that receives merged PRs          |
| `<pr-number>`        | `42`                   | Optional — pin to a specific PR          |
| `<watched-folder>`   | `docs`                 | Folder to watch for Markdown changes     |
| `<hld-output-path>`  | `docs`                 | Directory where the HLD is written       |
| `<hld-output-file>`  | `HLD.md`               | File name for the generated HLD          |

---

## Optional Additions

Append any of these lines to the prompt above when needed:

- `"Use Mermaid diagrams wherever flow or relationships are described."`
- `"Keep the HLD concise — one page if possible."`
- `"Include line references back to the source Markdown files."`
- `"Follow the existing documentation style in the repository."`
- `"Only consider Markdown files changed in the PR, not all files in the folder."`

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
              ├─ Find *.md files in <watched-folder>
              │       │
              │       └─ None found? ──► Warning, stop
              │
              └─ Run .github/scripts/generate-hld.sh
                        │
                        └─ Write HLD to <hld-output-path>/<hld-output-file>
                                  │
                                  └─ Upload as workflow artifact "hld-document"
```

---

## Configuration

The workflow is configured via environment variables at the top of
`.github/workflows/hld-generator.yml`:

```yaml
env:
  TARGET_BRANCH:  main        # branch that receives merged PRs
  WATCHED_FOLDER: docs        # folder to watch for Markdown changes
  HLD_OUTPUT:     docs/HLD.md # output HLD path/file name
```

Change these three values to adapt the workflow to any project or folder layout.
