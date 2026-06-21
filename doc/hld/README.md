# High-Level Design (HLD)

This folder contains auto-generated High-Level Design documents.

One `*-hld.md` file is created or updated for each requirement Markdown file
that changes in a merged pull request. For example:

- `doc/requirements/payment-flow.md` → `doc/hld/payment-flow-hld.md`
- `doc/requirements/user-authentication.md` → `doc/hld/user-authentication-hld.md`

Files are generated automatically by the **HLD Generator** workflow
(`.github/workflows/hld-generator.yml`) whenever a pull request that changes
`doc/requirements/` is merged into `main`.

Do **not** edit `*-hld.md` files by hand — your changes will be overwritten on
the next automated run. To update an HLD, update the corresponding source
requirement file in `doc/requirements/` instead.
