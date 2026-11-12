# Todoist setup

## Projects

| Project | Kind | Holds |
| --- | --- | --- |
| Inbox | Built in | Cards that haven't been triaged |
| `MECA` | Area, top level | One-off work cards |
| `Side Projects` | Area, top level | One-off side project cards |
| Feature project | Child of an area | The cards for one feature, such as `MECA › Appointment sync` |
| `Someday` | Top level | Ideas you might do later |

- A feature gets its own project when it needs several cards or more than a week of work. A job with two or three steps fits on one card with subtasks.
- Archive a feature project when it ships.
- There's no limit on the number of projects.

## Priorities

| Priority | Eisenhower quadrant | Meaning |
| --- | --- | --- |
| p1 | Do | Urgent and important |
| p2 | Schedule | Important but not urgent. The frog is a p2 card. |
| p3 | Delegate | Urgent but not important. The card carries `@waiting`. |
| p4 | None | Not triaged yet |

Dropped cards are deleted, so they have no priority.

## Labels

| Label | Meaning | Added by |
| --- | --- | --- |
| `@waiting` | An agent or a person holds the work | You, during triage |
| `@stale` | No activity for 21 days | The stale sweep |

## Filters

| Filter | Query | Settings |
| --- | --- | --- |
| Next | `(p1 \| p2) & !@waiting` | Group by project. Sort by priority. |
| Review | `@stale \| @waiting` | None |

The morning pick comes from Next. The Friday review works through Review.

## Today

Today is Todoist's built-in Today view. A card you don't finish stays dated, so it shows up again at the next morning pick. There, you keep it or clear its date.

## Recurring cards

| Card | Due string | Purpose |
| --- | --- | --- |
| Morning pick | `every workday` | Reminds you to run `/pick` |
| Friday review | `every friday` | Reminds you to run `/weekly-review` |

Keep both cards out of the Inbox, so triage never sees them. Leave them at p4, so they never show up in Next. They don't count toward the three-card pick.
