# Todoist setup

This page is the target layout. During setup, delete every label, filter, and section that this page doesn't list, and archive every project it doesn't list. Move the open cards out first, because deleting a section or a project deletes its cards.

## Projects

| Project | Kind | Holds |
| --- | --- | --- |
| Inbox | Built in | Cards that haven't been triaged |
| `MECA` | Area, top level | One-off work cards |
| `Side Projects` | Area, top level | One-off side project cards |
| `Personal` | Area, top level | Personal one-off cards, such as booking a dentist appointment |
| Feature project | Child of an area | The cards for one feature, such as `MECA › Appointment sync` |
| `Someday` | Top level | Ideas you might do later, at p4 |
| `Routines` | Top level | Repeating cards, such as meditating and the budget |

- A feature gets its own project when it needs several cards or more than a week of work. A job with two or three steps fits on one card with subtasks.
- Archive a feature project when it ships.
- There's no limit on the number of projects.
- Projects have no sections.

## Priorities

| Priority | Eisenhower quadrant | Meaning |
| --- | --- | --- |
| p1 | Do | Urgent and important |
| p2 | Schedule | Important but not urgent. The frog is a p2 card. |
| p3 | Delegate | Urgent but not important. For now, the priority is the only marker, and Next lists p3 cards after p1 and p2. |
| p4 | None | Not triaged yet, for a card in the Inbox. Routines and `Someday` cards also stay at p4. |

Dropped cards are deleted, so they have no priority.

## Labels

These are the only two labels.

| Label | Meaning | Added by |
| --- | --- | --- |
| `@waiting` | A person or a third party holds the work. A card that an agent works on doesn't get it. | You, during triage or later |
| `@stale` | No activity for 21 days | `/weekly-review`, or `/morning-pick` during a fresh start |

## Filters

These are the only two filters. Today is Todoist's built-in view, not a filter.

| Filter | Query | Settings |
| --- | --- | --- |
| Next | `(p1 \| p2 \| p3) & !@waiting & !#Someday` | Group by project. Sort by priority. |
| Review | `@stale \| @waiting` | None |

The morning pick comes from Next. The Friday review works through Review.

## Dates and deadlines

| Field | Meaning | Set by |
| --- | --- | --- |
| Date | You plan to work on the card today | `/morning-pick`, `/pick-next`, or you for an urgent p1 card |
| Deadline | The card is actually due that day | You, during triage or later |

- Only the two pick skills and urgent p1 cards put dates on work cards, so an overdue card is always one you picked and didn't finish.
- Routines use repeating dates. See [Routines](#routines).
- Deadlines need Todoist Pro.

## Today

Today is Todoist's built-in Today view. Group it by project, so routines sit in their own group. Today is also the in-progress list. A card still on Today the next morning is multi-day work you haven't finished. At the morning pick, you keep it or clear its date.

## Routines

Routines live in the `Routines` project at p4. They never show up in Next, and they never count toward the five-card pick.

| Repeat type | Use it for | Example due string |
| --- | --- | --- |
| `every` | A routine tied to the calendar. Completing an overdue card moves it to its next future date. | `every day` |
| `every!` | A routine that repeats from when you last did it | `every! week` |

The morning pick and the Friday review have no cards. Scheduled tasks start them. See [AI jobs](ai-jobs.md).
