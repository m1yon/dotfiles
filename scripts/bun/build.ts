#!/usr/bin/env bun
import { Glob } from "bun";
import { mkdir, rm } from "node:fs/promises";
import { basename, dirname, join } from "node:path";

const BIN_DIR = "bin";
const SOURCE_ROOT = "src";
const ENTRY_PATTERN = "src/*/index.ts";
const SHARED_SCOPE = "shared";
const SCOPE_ORDER = [SHARED_SCOPE, "darwin", "linux"];

interface ScriptPackage {
  scope: string;
  dir: string;
}

interface EntryPoint {
  name: string;
  scope: string;
  entry: string;
  output: string;
}

interface BuildResult extends EntryPoint {
  success: boolean;
  error?: string;
}

function compareScopes(a: string, b: string): number {
  const aIndex = SCOPE_ORDER.indexOf(a);
  const bIndex = SCOPE_ORDER.indexOf(b);

  if (aIndex !== -1 && bIndex !== -1) return aIndex - bIndex;
  if (aIndex !== -1) return -1;
  if (bIndex !== -1) return 1;

  return a.localeCompare(b);
}

function currentPlatformScope(): string | null {
  if (process.platform === "darwin") return "darwin";
  if (process.platform === "linux") return "linux";
  return null;
}

async function findPackages(): Promise<ScriptPackage[]> {
  const packages: ScriptPackage[] = [];

  for (const scope of SCOPE_ORDER) {
    const dir = join(SOURCE_ROOT, scope);
    if (!(await Bun.file(join(dir, "package.json")).exists())) continue;

    packages.push({ scope, dir });
  }

  return packages.sort((a, b) => compareScopes(a.scope, b.scope));
}

async function findEntryPoints(pkg: ScriptPackage): Promise<EntryPoint[]> {
  const glob = new Glob(ENTRY_PATTERN);
  const entries: EntryPoint[] = [];

  for await (const file of glob.scan({ cwd: pkg.dir, absolute: false })) {
    const entry = join(pkg.dir, file);
    const name = basename(dirname(entry));
    entries.push({
      name,
      scope: pkg.scope,
      entry,
      output: join(BIN_DIR, pkg.scope, name),
    });
  }

  return entries.sort((a, b) => a.name.localeCompare(b.name));
}

function selectPackages(packages: ScriptPackage[]): ScriptPackage[] {
  const args = Bun.argv.slice(2);
  const allScopes = new Set(packages.map((pkg) => pkg.scope));

  if (args.includes("--all")) return packages;

  const explicitScopes = args.filter((arg) => !arg.startsWith("-"));
  if (explicitScopes.length > 0) {
    for (const scope of explicitScopes) {
      if (!allScopes.has(scope)) {
        throw new Error(`Unknown Bun script scope: ${scope}`);
      }
    }

    return packages.filter((pkg) => explicitScopes.includes(pkg.scope));
  }

  const platformScope = currentPlatformScope();
  const defaultScopes = [SHARED_SCOPE, platformScope].filter(
    (scope): scope is string => scope !== null && allScopes.has(scope),
  );

  return packages.filter((pkg) => defaultScopes.includes(pkg.scope));
}

function assertNoPathCollisions(entries: EntryPoint[]): void {
  const byName = new Map<string, EntryPoint[]>();

  for (const entry of entries) {
    const existing = byName.get(entry.name) ?? [];
    existing.push(entry);
    byName.set(entry.name, existing);
  }

  const conflicts = [...byName.entries()].filter(([, scripts]) => {
    const scopes = new Set(scripts.map((script) => script.scope));
    return scopes.has(SHARED_SCOPE) && scopes.size > 1;
  });

  if (conflicts.length === 0) return;

  const lines = conflicts.map(([name, scripts]) => {
    const scopes = scripts.map((script) => script.scope).sort().join(", ");
    return `  ${name}: ${scopes}`;
  });

  throw new Error(
    [
      "Bun script names cannot exist in shared and a platform scope at the same time.",
      "That would make PATH behavior depend on directory order.",
      ...lines,
    ].join("\n"),
  );
}

async function cleanBinDir(): Promise<void> {
  await rm(BIN_DIR, { recursive: true, force: true });
  await mkdir(BIN_DIR, { recursive: true });
}

async function buildEntry(entry: EntryPoint): Promise<BuildResult> {
  await mkdir(dirname(entry.output), { recursive: true });

  const proc = Bun.spawn(
    ["bun", "build", "--compile", entry.entry, "--outfile", entry.output],
    { stdout: "pipe", stderr: "pipe" },
  );

  const exitCode = await proc.exited;
  const stderr = await new Response(proc.stderr).text();

  return {
    ...entry,
    success: exitCode === 0,
    error: exitCode !== 0 ? stderr.trim() : undefined,
  };
}

async function main() {
  const packages = await findPackages();
  const selectedPackages = selectPackages(packages);
  const selectedScopes = selectedPackages.map((pkg) => pkg.scope).join(", ");

  console.log(`Finding entry points for scope(s): ${selectedScopes}`);

  const allEntries = (await Promise.all(packages.map(findEntryPoints))).flat();
  assertNoPathCollisions(allEntries);

  const selectedScopeSet = new Set(selectedPackages.map((pkg) => pkg.scope));
  const entries = allEntries.filter((entry) => selectedScopeSet.has(entry.scope));

  if (entries.length === 0) {
    console.log("No entry points found.");
    process.exit(0);
  }

  console.log(`Found ${entries.length} entry point(s):`);
  entries.forEach((entry) => {
    console.log(`  ${entry.scope}: ${entry.entry}`);
  });
  console.log();

  console.log("Cleaning bin/ directory...");
  await cleanBinDir();

  console.log("Building...\n");
  const results = await Promise.all(entries.map(buildEntry));

  const successful = results.filter((result) => result.success);
  const failed = results.filter((result) => !result.success);

  if (successful.length > 0) {
    console.log(`Built ${successful.length} binary(ies):`);
    successful.forEach((result) => console.log(`  ${result.output}`));
  }

  if (failed.length > 0) {
    console.log(`\nFailed ${failed.length} build(s):`);
    failed.forEach((result) => {
      console.log(`  ${result.scope}/${result.name}: ${result.error}`);
    });
    process.exit(1);
  }

  console.log("\nBuild complete!");
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
