# Stories

This folder contains auto-generated implementation story documents.

One `*-stories.md` file is created for each changed `doc/lld/*-lld.md` file in a
merged pull request. For example:

- `doc/lld/payment-flow-lld.md` → `doc/stories/payment-flow-stories.md`
- `doc/lld/user-authentication-lld.md` → `doc/stories/user-authentication-stories.md`

Files are generated automatically by the **Story Generator** workflow
(`.github/workflows/story-generator.yml`) whenever a pull request is merged into
`main` and includes new or modified LLD files matching `doc/lld/*-lld.md`.

## How generation works

For each changed LLD file, the generator correlates:

- the matching requirement file in `doc/requirements/`
- the matching HLD file in `doc/hld/`
- the changed LLD file in `doc/lld/`

The workflow clears previously generated `*-stories.md` files before writing the
new output set so story generation always starts from a clean stories folder.
This `README.md` is kept as the stable explanation for the folder.

## Story document structure

Each generated story file contains:

| Section | Description |
|---------|-------------|
| **Generation Context** | Source requirement, HLD, and LLD files used for story generation |
| **Design Signals Used** | Design cues detected from the correlated documents |
| **Ordered Jira Stories** | Sequenced backlog table with story ID, level, priority, dependency order, and description |
| **Acceptance Criteria** | Story-by-story delivery checks for implementation readiness |

## Interpreting order and priority

- **Sequence / Execution Order** defines the intended delivery order.
- **Depends On** lists predecessor sequence numbers that should be completed first.
- **Priority** indicates which work should be started earliest when multiple items
  are available, but dependencies always take precedence over priority.
- Earlier stories establish the foundations needed for later stories, such as
  domain setup, contracts, integrations, workflow orchestration, and validation.

Do **not** edit `*-stories.md` files by hand — the next automated run will
overwrite them. To change generated stories, update the source requirement, HLD,
or LLD documents instead.
