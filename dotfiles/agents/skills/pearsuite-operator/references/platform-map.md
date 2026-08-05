# Platform map

Verified in production on 2026-08-05.

## Organization shell

- Production base: `https://app.pearsuite.com/meca-therapies/`
- Sandbox paths contain `/meca-therapies-sandbox/`.
- The organization selector appears near the top of the application shell.
- Main navigation includes Dashboard, Members, Builder, Templates, and Data Management.

Use visible roles, labels, and exact accessible names. Scope ambiguous controls to the selected tabpanel or visible dialog because inactive tab content and custom dropdown portals can remain in the DOM.

Organization Settings are a prohibited route. Do not open or inspect that page. The organization selector label may be read only as the environment signal defined in `safety-and-verification.md`.

## Template routes

Opening `/meca-therapies/templates` redirects to Activities.

| Area | Production route | Primary controls |
|---|---|---|
| Activities | `/meca-therapies/templates/activities` | `By Title`, `Add Activity Template` |
| Flows | `/meca-therapies/templates/flows` | `Search by title...`, `Add Flow Template` |

The Templates workspace also exposes Goals, Emails, Care Pathways, Care Plans, Events, Note Templates, Consents, PDF Templates, and Review Requests. Those areas are not yet documented for write operations.

The Activities table currently shows Title, Tasks, Tags, Tracking, and Retire columns. The Flows table shows Title, Type, Version, Locked, Copy, Export, and Retire. Tables are paginated, so use their search field rather than scanning only the visible page.

## Data Management routes

- Base: `/meca-therapies/data-management`
- Questions: `/meca-therapies/data-management?tab=questions`

The Data tab searches `By Data ID or Title` and exposes `Create Data`. The Questions tab uses the same search placeholder and exposes `Create Question`.

Data IDs are not a sufficient unique key for question rows: production displayed more than one question row with `ADL01`. When matching an existing question, verify data ID, title, question text, answer type, and options together.

## Builder routes and labels

- A new activity opened at `/meca-therapies/builder/activities/create/create` during inspection.
- Existing flow routes contain the flow UUID twice under `/builder/flows/.../...`; do not construct or guess these routes. Open rows from the Templates table.
- Builder pages include a `Back` control and may show a button labeled `Update Activity Template` even on a create route. Do not use button wording as proof that an object already exists.
