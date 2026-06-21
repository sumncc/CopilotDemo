# Story Generator — Agent Prompt Template

Use this template as the starting point for a cloud agent session whenever you
want to manually trigger (or re-trigger) story generation from a specific merged
pull request.

---

## Reusable Prompt Template

Copy the block below, fill in the placeholders, and paste it into your cloud
agent (e.g. GitHub Copilot Coding Agent in IntelliJ or the web UI).

```
Inspect repository `<owner/repo>` on branch `<target-branch>`.

Task:
1. Find the most recently merged pull request into `<target-branch>` (or PR #<pr-number> if known).
2. Check whether any files matching `<lld-folder>/*-lld.md` were added or modified in that PR.
3. If matching LLD files changed, clear `<story-output-dir>/` before generating new stories.
4. For each changed LLD file:
   - locate the related requirement file in `<requirements-folder>`
   - locate the related HLD file in `<hld-folder>`
   - read the requirement, HLD, and LLD documents together
   - derive ordered implementation stories that respect dependency order
5. Generate one output file per changed LLD file at
   `<story-output-dir>/<basename>-stories.md`, where `<basename>` is the LLD
   filename without the `-lld.md` suffix. For example:
   - `<lld-folder>/payment-flow-lld.md` → `<story-output-dir>/payment-flow-stories.md`
   - `<lld-folder>/user-authentication-lld.md` → `<story-output-dir>/user-authentication-stories.md`
6. Each generated story file must include:
   - Generation Context
   - Ordered Jira Stories table
   - Sequence number or Story ID
   - Jira title
   - Jira level/type
   - Priority
   - Dependency / predecessor information
   - Acceptance criteria
7. Ensure task ordering reflects implementation dependency:
   - foundational setup first
   - data model / contracts next
   - backend/services next
   - integrations next
   - UI/workflow next
   - testing / validation / deployment tasks afterward
8. Upload the generated story files as artifacts and open a follow-up pull request.
9. Do not modify any application source code or unrelated files.
```

---

## Placeholder Reference

| Placeholder              | Example value          | Description                                      |
|--------------------------|------------------------|--------------------------------------------------|
| `<owner/repo>`           | `sumncc/CopilotDemo`   | GitHub repository in `owner/repo` format         |
| `<target-branch>`        | `main`                 | Branch that receives merged PRs                  |
| `<pr-number>`            | `42`                   | Optional — pin to a specific PR                  |
| `<requirements-folder>`  | `doc/requirements`     | Folder containing source requirements            |
| `<hld-folder>`           | `doc/hld`              | Folder containing generated HLD files            |
| `<lld-folder>`           | `doc/lld`              | Folder containing generated LLD files            |
| `<story-output-dir>`     | `doc/stories`          | Directory where generated story files are stored |

---

## How the Automation Works

```
PR merged into <target-branch>
        │
        ▼
GitHub Actions: story-generator.yml
        │
        ├─ Did <lld-folder>/ change? ──No──► Stop (no-op)
        │
        └─ Yes
              │
              ├─ Find added or modified *-lld.md files
              │       │
              │       └─ None found? ──► Warning, stop
              │
              ├─ Clear <story-output-dir>/ generated files
              │
              └─ Run .github/scripts/generate-stories.sh
                        │
                        └─ For each changed LLD file:
                                  │
                                  ├─ Read matching requirement, HLD, and LLD
                                  ├─ Derive ordered implementation stories
                                  ├─ Write <story-output-dir>/<basename>-stories.md
                                  └─ Upload artifact "story-documents"
```

---

## Configuration

The workflow is configured via environment variables at the top of
`.github/workflows/story-generator.yml`:

```yaml
env:
  TARGET_BRANCH: main
  WATCHED_FOLDER: doc/lld
  STORY_OUTPUT_DIR: doc/stories
```

Change these values to adapt the workflow to any project or folder layout.
