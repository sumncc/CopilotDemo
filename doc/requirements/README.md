# Requirements

Place requirement Markdown files in this folder.

Any `.md` file added or updated here (excluding `README.md`) and merged into
`main` will automatically trigger the HLD Generator workflow. The workflow
generates one HLD file per changed requirement file in `doc/hld/`:

- `doc/requirements/payment-flow.md` → `doc/hld/payment-flow-hld.md`
- `doc/requirements/user-authentication.md` → `doc/hld/user-authentication-hld.md`

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

The HLD generator will create a separate `doc/hld/<name>-hld.md` for each
requirement file, including the file's content and structural stub sections
(Components, Data/Control Flow, Assumptions, Open Questions) for a developer
or cloud agent to complete.
