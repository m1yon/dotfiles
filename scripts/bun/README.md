# scripts/bun

Bun CLI scripts compiled into standalone binaries.

## Layout

```text
src/shared/src/<script>/index.ts  # cross-platform scripts
src/darwin/src/<script>/index.ts  # macOS-only scripts
src/linux/src/<script>/index.ts   # Linux-only scripts
bin/<scope>/<script>              # generated binaries
```

## Common Commands

```bash
bun install
bun run build
bun run test
bun run typecheck
```

`bun run build` builds `shared` plus the current platform by default.
