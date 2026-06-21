# Low-Level Design (LLD)

This folder contains auto-generated Low-Level Design documents.

One `*-lld.md` file is created or updated for each HLD Markdown file
that changes in a merged pull request. For example:

- `doc/hld/payment-flow-hld.md` → `doc/lld/payment-flow-lld.md`
- `doc/hld/user-authentication-hld.md` → `doc/lld/user-authentication-lld.md`

Files are generated automatically by the **LLD Generator** workflow
(`.github/workflows/lld-generator.yml`) whenever a pull request is merged into
`main` and includes changes to either:

- `doc/hld/*-hld.md` — an HLD file was added or updated, or
- `doc/lld/` — an existing LLD file was modified (the automation re-syncs it
  from its corresponding HLD source).

## LLD → Stories pipeline

When a merged pull request adds or modifies `doc/lld/*-lld.md`, the
**Story Generator** workflow (`.github/workflows/story-generator.yml`)
correlates the matching requirement, HLD, and LLD files and generates ordered
implementation story files under `doc/stories/`:

- `doc/lld/payment-flow-lld.md` → `doc/stories/payment-flow-stories.md`
- `doc/lld/user-authentication-lld.md` → `doc/stories/user-authentication-stories.md`

Before each story-generation run, the workflow clears previously generated
`doc/stories/*-stories.md` files so the output always starts from a clean set.
See [`doc/stories/README.md`](../stories/README.md) for details on the story
format, sequencing rules, and priority handling.

## LLD document structure

Each generated LLD file contains the following sections:

| Section | Description |
|---------|-------------|
| **Overview** | A short summary extracted from the HLD file |
| **Sequence Diagram** | A fenced Mermaid `sequenceDiagram` block showing interactions between participants derived from the HLD content |
| **Flow Diagram** | A fenced Mermaid `flowchart LR` block showing the data and control flow derived from the HLD content |
| **Components / Modules** | Table of main components/modules (placeholder for developer or agent to complete) |
| **Assumptions** | Assumptions extracted from the HLD file |
| **Open Questions** | Placeholder for open decisions |

### Example Sequence Diagram

```mermaid
sequenceDiagram
  participant User
  participant UI[UI / Frontend]
  participant API[My Feature API]
  participant DB[(Data Store)]

  User->>UI: Submit request
  UI->>API: POST /request
  API->>DB: Read / Write data
  DB-->>API: Result
  API-->>UI: Response
  UI-->>User: Display result
```

### Example Flow Diagram

```mermaid
flowchart LR

  subgraph System["My Feature"]
    MyfeatureAPI[My Feature API]
    DB[(Data Store)]
  end

  User([User]) --> UI[UI / Frontend]
  UI --> MyfeatureAPI
  MyfeatureAPI --> DB
```

Do **not** edit `*-lld.md` files by hand — your changes will be overwritten on
the next automated run. To update an LLD, update the corresponding source HLD
file in `doc/hld/` instead.
