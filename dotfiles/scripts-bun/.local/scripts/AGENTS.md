# Bun Scripts Repository

CLI tools built with Bun, compiled to standalone executables.

## Structure

```
src/<script-name>/
  index.ts      # Entry point (required)
  types.ts      # Type definitions
  *.ts          # Supporting modules
scripts/
  build.ts      # Build script
bin/            # Compiled binaries (gitignored)
```

## Creating a New Script

1. Create a directory under `src/` with your script name
2. Add an `index.ts` as the entry point
3. Run `bun run build` to compile

```bash
mkdir src/my-tool
# Create src/my-tool/index.ts
bun run build  # Creates bin/my-tool
```

### Front Matter

Every script must include a front matter block with a description. This is parsed by `ls-scripts` to display a summary of all available scripts. Place it immediately after the shebang line:

```typescript
#!/usr/bin/env bun
// ---
// description: Short description of what the script does
// ---
```

### Entry Point Template

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

- Finds all `src/*/index.ts` entry points
- Compiles each to a standalone binary in `bin/`
- Binary name matches directory name (e.g., `src/foo/index.ts` → `bin/foo`)

## Conventions

### Module Organization

- `types.ts` - Type definitions and interfaces
- `errors.ts` - Custom error classes
- Keep entry point (`index.ts`) focused on CLI parsing and orchestration
- Extract business logic to separate modules

### Error Handling

Create typed errors for different failure modes:

```typescript
export class MyToolError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MyToolError";
  }
}
```

### Interactive Prompts

Use `@inquirer/prompts` for user interaction:

```typescript
import { select } from "@inquirer/prompts";

const choice = await select({
  message: "Select an option",
  choices: items.map((item) => ({ name: item.label, value: item })),
});
```

## Things to Watch Out For

1. **Entry point must be `index.ts`** - The build script only looks for `src/*/index.ts`

2. **Shebang for direct execution** - Include `#!/usr/bin/env bun` at the top of `index.ts`

3. **Dependencies are bundled** - `bun build --compile` bundles all dependencies into the binary; no need to install on target machine

4. **ES Modules only** - Use `import`/`export`, not `require`/`module.exports`

5. **Type safety** - tsconfig has strict settings enabled (`noUncheckedIndexedAccess`, etc.); handle undefined cases explicitly
