# Bun Scripts Repository

CLI tools built with Bun and compiled to standalone executables.

## Structure

```
src/
  shared/                 # Cross-platform Bun scripts
    package.json          # Runtime deps for shared scripts
    src/<script-name>/
      index.ts            # Entry point
  darwin/                 # macOS-only Bun scripts
    package.json
    src/<script-name>/
      index.ts
  linux/                  # Linux-only Bun scripts
    package.json
    src/<script-name>/
      index.ts
build.ts                  # Build script
bin/                      # Compiled binaries, gitignored
```

## Creating a New Script

1. Pick the narrowest scope:
   - `src/shared` for cross-platform scripts
   - `src/darwin` for macOS-only scripts
   - `src/linux` for Linux-only scripts
2. Add `src/<script-name>/index.ts` under that package.
3. Add runtime dependencies to that package's `package.json`.
4. Run `bun install` in `scripts/bun/` if dependency metadata changed.
5. Run `bun run build`.

Example:

```bash
mkdir -p src/shared/src/my-tool
# Create src/shared/src/my-tool/index.ts
bun run build  # Creates bin/shared/my-tool on every platform
```

## Front Matter

Every script must include a front matter block with a description. This is parsed by `ls-scripts` to display a summary of all available scripts. Place it immediately after the shebang line:

```typescript
#!/usr/bin/env bun
// ---
// description: Short description of what the script does
// ---
```

## Entry Point Template

```typescript
#!/usr/bin/env bun
// ---
// description: Example tool that does something useful
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .option("example", {
      alias: "e",
      type: "string",
      description: "Example option",
    })
    .help()
    .alias("h", "help")
    .parse();

  // Your logic here
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
```

## Build Process

```bash
bun run build
```

- Finds `src/shared/src/*/index.ts`.
- Also finds the current platform scope: `src/darwin` on macOS, `src/linux` on Linux.
- Compiles each script to `bin/<scope>/<script-name>`.
- Fails if a script name exists in both `shared` and a platform scope, because that would make PATH behavior depend on directory order.

To build explicit scopes:

```bash
bun run build shared
bun run build linux
bun run build --all
```

## Dependency Rules

- Keep runtime dependencies in the package that owns the script.
- Keep root dependencies limited to workspace/dev tooling.
- `bun install` is allowed here for repo-local dependency and lockfile updates.
- Do not use Bun, npm, or another language package manager for global/system installs.

## Conventions

- `types.ts` - Type definitions and interfaces
- `errors.ts` - Custom error classes
- Keep entry points focused on CLI parsing and orchestration
- Extract business logic to separate modules

## Things to Watch Out For

1. Entry point must be `index.ts`; the build script only scans `src/*/index.ts` inside each package.
2. Include `#!/usr/bin/env bun` at the top of `index.ts` for direct execution.
3. Dependencies are bundled by `bun build --compile`.
4. Use ES modules: `import`/`export`, not `require`/`module.exports`.
5. Type safety is strict; handle undefined cases explicitly.
