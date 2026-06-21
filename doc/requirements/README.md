# Requirements

Place requirement Markdown files in this folder.

Any `.md` file added or updated here and merged into `main` will automatically
trigger the HLD Generator workflow, which reads all files in this folder and
produces (or updates) `doc/hld/HLD.md`.

## File naming

Use descriptive, lower-case, hyphen-separated names, for example:

```
doc/requirements/
  user-authentication.md
  payment-flow.md
  notification-service.md
```

## What to include in a requirement file

Each file should describe one feature area or sub-system. A typical structure:

```markdown
# <Feature name>

## Overview
Short description of the feature.

## Functional requirements
- FR-1: ...
- FR-2: ...

## Non-functional requirements
- NFR-1: ...

## Assumptions
- ...

## Out of scope
- ...
```

The HLD generator will inline the content of every file here into the HLD
document and provide structural stub sections (Components, Data/Control Flow,
Assumptions, Open Questions) for a developer or cloud agent to complete.
