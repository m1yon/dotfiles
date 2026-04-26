---
type: ifs_home
crisis_fallback: [[Crisis Plan]]
---

# IFS

## Active parts
```dataview
table part_type as "type", last_seen
from "6 - Full Notes/IFS/Parts"
where status = "active"
sort last_seen desc
```

## Relationships
```dataview
table protects, polarized_with, allies
from "6 - Full Notes/IFS/Parts"
where status = "active" and (protects or polarized_with or allies)
```

## Unburdened
```dataview
list from "6 - Full Notes/IFS/Parts" where status = "unburdened"
```
