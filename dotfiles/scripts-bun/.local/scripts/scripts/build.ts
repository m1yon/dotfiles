#!/usr/bin/env bun
import { Glob } from "bun";
import { rm, mkdir } from "node:fs/promises";
import { basename, dirname, join } from "node:path";

const SRC_DIR = "src";
const BIN_DIR = "bin";
const ENTRY_PATTERN = "*/index.ts";

interface BuildResult {
  name: string;
  entry: string;
  output: string;
  success: boolean;
  error?: string;
}

async function findEntryPoints(): Promise<string[]> {
  const glob = new Glob(ENTRY_PATTERN);
  const entries: string[] = [];
  for await (const file of glob.scan({ cwd: SRC_DIR, absolute: false })) {
    entries.push(join(SRC_DIR, file));
  }
  return entries.sort();
}

async function cleanBinDir(): Promise<void> {
  await rm(BIN_DIR, { recursive: true, force: true });
  await mkdir(BIN_DIR, { recursive: true });
}

async function buildEntry(entry: string): Promise<BuildResult> {
  // src/ecs-trigger/index.ts → ecs-trigger
  const name = basename(dirname(entry));
  const output = join(BIN_DIR, name);

  const proc = Bun.spawn(
    ["bun", "build", "--compile", entry, "--outfile", output],
    { stdout: "pipe", stderr: "pipe" }
  );

  const exitCode = await proc.exited;
  const stderr = await new Response(proc.stderr).text();

  return {
    name,
    entry,
    output,
    success: exitCode === 0,
    error: exitCode !== 0 ? stderr.trim() : undefined,
  };
}

async function main() {
  console.log("Finding entry points...");
  const entries = await findEntryPoints();

  if (entries.length === 0) {
    console.log("No entry points found matching src/*/index.ts");
    process.exit(0);
  }

  console.log(`Found ${entries.length} entry point(s):`);
  entries.forEach((e) => console.log(`  ${e}`));
  console.log();

  console.log("Cleaning bin/ directory...");
  await cleanBinDir();

  console.log("Building...\n");
  const results = await Promise.all(entries.map(buildEntry));

  // Report results
  const successful = results.filter((r) => r.success);
  const failed = results.filter((r) => !r.success);

  if (successful.length > 0) {
    console.log(`Built ${successful.length} binary(ies):`);
    successful.forEach((r) => console.log(`  ${r.output}`));
  }

  if (failed.length > 0) {
    console.log(`\nFailed ${failed.length} build(s):`);
    failed.forEach((r) => {
      console.log(`  ${r.name}: ${r.error}`);
    });
    process.exit(1);
  }

  console.log("\nBuild complete!");
}

main();
