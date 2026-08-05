# Regression fixtures

## IBCLC SOAP production fixture

Verified in production on 2026-08-05 as flow `IBCLC SOAP`, type `Script`, version `3`.

| ID | Title | Type / options |
|---|---|---|
| `IBCLC01` | IBCLC Evaluation | Choose One: In-person, Telehealth |
| `IBCLC02` | Subjective | Text |
| `IBCLC03` | Objective | Text |
| `IBCLC04` | Assessment | Text |
| `IBCLC05` | Plan | Text |
| `IBCLC06` | Next Step | Choose One: Yes, No |
| `IBCLC07` | Schedule Lactation Outreach | Choose One: Yes, No |

Expected structure:

```text
Start -> IBCLC01 -> IBCLC02 -> IBCLC03
      -> IBCLC04 -> IBCLC05 -> IBCLC06 -> IBCLC07
```

The production builder displayed the seven questions in sequence. `IBCLC07 -> Yes` displayed an Activity action targeting `Doula/Lactation Outreach Attempt`.

The historical sandbox dependency was named `Doula/Lactation Outreach`, without `Attempt`. Treat this as a cross-environment mismatch and pause instead of mapping it automatically.

Use this fixture only for read-only regression checks. Validate structure and action labels from the visible builder, but never save merely to test the skill. User approval alone does not authorize a fixture mutation.
