---
name: architecture-diagram
description: Generate a Mermaid call-graph diagram of a Go and/or TypeScript repo. Renders left-to-right with the entry point on the left. Each module is a subgraph (direction TB so symbols stack vertically), one node per public symbol with signature, body LOC, param count, and per-symbol ratio. Edges link function-to-function (not module-to-module) — A → B means A's body references B's exported symbol. Module subgraphs show I/L/R headers and are color-bucketed by LOC/interface ratio. Writes to `docs/architecture.mmd`. Use when the user wants to audit AI-generated code, spot shallow modules or shallow public functions, see public interface signatures, or trace the call graph from the entry point outward.
---

# Architecture diagram

Emits a single Mermaid `flowchart LR` at `docs/architecture.mmd`:

- **Layout**: left-to-right. Entry points (no incoming edges) sit on the left; called functions appear to the right of their callers.
- **Module subgraph**: one per source-bearing directory. `direction TB` so symbols stack vertically. Header: `path • I:interface_count L:LOC R:LOC/I`. Background tinted by R bucket.
- **Symbol nodes**: one per public export. Label: full signature + `L:body_LOC P:param_count R:body_LOC/max(P,1)`.
- **Edges**: function → function. `A.foo --> B.bar` with weight = number of references to `B.bar` inside `A.foo`'s body.

R is a **screening proxy**, not a verdict. Surface candidates with it; judge depth-as-leverage with [improve-codebase-architecture](../improve-codebase-architecture/SKILL.md).

## Quick start

```sh
bun ~/.claude/skills/architecture-diagram/scripts/analyze.ts > docs/architecture.mmd
```

Targets cwd by default. Pass a subdir to scope:

```sh
bun ~/.claude/skills/architecture-diagram/scripts/analyze.ts src/api > docs/api-architecture.mmd
```

Requires `bun` on `PATH`. No `npm install` — pure `node:fs` / `node:path`.

**Renderer requirements:** the output uses HTML-styled labels for left-aligned, color-coded signatures. View in:
- **mermaid.live** (default config supports it)
- **VS Code Mermaid Preview / Markdown Preview Mermaid Support** (default supports it)
- Any renderer with `securityLevel: 'loose'` and `flowchart.htmlLabels: true` (the diagram emits an init directive that requests both).
- GitHub's inline Mermaid renders the labels but strips most styling; for critical review, use mermaid.live.

## Workflow

1. `mkdir -p docs` if missing.
2. Run from repo root. It auto-detects Go (via `go.mod`) and TypeScript (via `tsconfig.json`).
3. Write output to `docs/architecture.mmd` (or scoped name if a subdir was given).
4. Summarize for the user:
   - 3 modules with the highest **R** (likely-deep candidates worth preserving)
   - 3 modules with the lowest R but non-trivial fan-in (shallow candidates worth reviewing)
   - Any **public function** with high P and low L (e.g. `R < 2`) — high interface, almost no implementation; classic shallow signal
   - The leftmost entry node(s) and 1–2 hop call chains worth attention
5. Suggest opening in a Mermaid renderer (VS Code Mermaid extension, mermaid.live, or `mmdc`).

## Reading the diagram

### Module subgraph
- **Header**: `path • I:N L:M R:X.Y` — N public symbols, M LOC, R = M/N.
- **Background color** (5 buckets): red → orange → grey → green by R. Greener = more impl per unit interface.
- **Dashed grey border** = entry module: Go `package main` (whose `main()` is extracted as a node), or any module with zero exported symbols. Look at outgoing edges, not R.

### Symbol node (inside subgraph)
- **Label**: left-aligned, monospace, in a min-width 360px box. Uses HTML+CSS via Mermaid's loose security level.
- **Signature**: kind keyword colored by kind (func/method = blue, class = magenta, interface = teal, struct = orange, enum = purple, type/var/const = grey), name in bold black, rest in dark grey. Truncated at ~140 chars.
- **Metrics line** (smaller font): `L:` `P:` `R:` labels in light grey, values in bold dark.
  - Callables (funcs, methods, arrow consts): `L:body_LOC  P:param_count  R:body_LOC/max(P,1)`.
  - Body-bearing non-callables (classes, interfaces, enums, structs): `L:body_LOC` only.
  - Inert (types, vars, consts, re-exports): no metrics line.
- **Border** (5 buckets): driven by R (callables) or L (classes/etc). Thicker = more impl per unit interface. Background stays white so signatures stay readable.

### Edges
- `caller --> callee` where both endpoints are individual symbol nodes. Weight = call sites.
- **Stroke width** (4 buckets): thicker = more references.
- When the callee falls outside the per-module visible cap (`MAX_DECLS_PER_MODULE`), the edge collapses to the destination subgraph; weights from one source to that subgraph are merged.

## What the metrics do and don't measure

Do:
- Surface modules and functions with **thin interfaces and lots of code behind them** (deep candidates).
- Surface modules that mostly re-export or pass through, and functions with many params doing very little (shallow signals).
- Show actual flow: which function calls which, starting from the entry.

Don't:
- Capture **leverage**. A 30-line module with one perfect function can be deeper than a 3000-line module with one bloated function. The metric won't see the difference.
- Capture interface complexity beyond symbol count and param count (invariants, ordering, error modes are invisible).
- Catch dynamic dispatch (interface satisfaction in Go, polymorphic method calls in TS) — only direct symbol references are counted.

Treat the diagram as a **starting map**. For real depth assessment, run [improve-codebase-architecture](../improve-codebase-architecture/SKILL.md) on what the diagram surfaces.

## Conventions

- **Module = directory** containing `.go`, `.ts`, or `.tsx` files. Nested dirs are separate modules.
- **Public interface**:
  - Go — top-level capitalized `func`/`method`/`type`/`var`/`const`. For `package main`, `main()` is also extracted.
  - TS — `export` declarations and `export { ... }` re-exports.
- **Body LOC** = brace-matched span of the function/class/interface/enum body, non-blank lines only. Strings and comments blanked before brace matching.
- **Param count** = top-level commas + 1 in the first parenthesized group of a callable's signature; 0 if empty.
- **Edge** A.foo → B.bar: A's body region (between body braces) references symbol `bar` resolved through A's imports of B.
  - Go: imported package `pkg "github.com/.../B"` → matches `pkg.Bar` references.
  - Go dot-imports: any of B's exports referenced as bare identifiers.
  - TS named imports: each imported name matched as a bare identifier in A's body. Aliased imports use the original exported name as the destination.
  - TS namespace imports: `alias.Name` extracted; destination is `Name` in B.
  - TS default imports: skipped (no reliable destination symbol name).
- **Excluded**: test files (`*_test.go`, `*.test.ts`, `*.spec.ts`), and standard build/dep dirs (`node_modules`, `vendor`, `dist`, `build`, `.next`, `out`).

## Limits

- Heuristic regex parsing — not a full AST. Specifically:
  - **TS functions returning inline type literals** (`function foo(): {x: number} { ... }`) may have body brace mis-detected.
  - **Go generics** with embedded function decls in unusual layouts may be missed.
  - **TS class methods** are not extracted as separate symbols (only top-level exports).
  - **`export = X`** and **dynamic `import()`** are not handled.
  - **Default imports** don't produce edges.
- Edge analysis only scans **callable bodies** (funcs, methods, arrow-const fns). References inside class/struct/interface bodies are not traced.
- Intra-module calls are only edged when they cross file boundaries via local imports (e.g. `import { x } from './sibling'`). Calls to bare identifiers within the same package/file are not traced.
- **Soft cap**: 15 declarations per module (sorted by body LOC desc). Excess shown as `+N more`. Edges to non-visible symbols collapse to the destination subgraph. Tweak `MAX_DECLS_PER_MODULE` in `analyze.ts` if needed.
- **Path-mapped TS imports** (`@/foo`) resolve only if `tsconfig.json` declares them under `compilerOptions.paths`; otherwise skipped.
- Repos > ~80 modules with full symbol detail and many edges may overwhelm Mermaid renderers. Scope with a subdir argument.
- The output sets `maxTextSize: 5000000` and `maxEdges: 10000` in its init directive (Mermaid defaults are 50000 / 500). If a renderer still reports "Maximum text size in diagram exceeded", it's ignoring init overrides — pass a subdir argument to scope, or lower `MAX_DECLS_PER_MODULE` in `analyze.ts`.
