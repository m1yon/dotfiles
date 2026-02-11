#!/usr/bin/env bun
// ---
// description: Deep merge two JSON files with sorted keys
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { deepMerge, sortKeysDeep } from "./merge.ts";

async function readJson(path: string): Promise<unknown> {
  const file = Bun.file(path);
  if (!(await file.exists())) {
    throw new Error(`File not found: ${path}`);
  }
  const text = await file.text();
  try {
    return JSON.parse(text);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    throw new Error(`Invalid JSON in ${path}: ${message}`);
  }
}

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .usage("Usage: $0 <file1> <file2>")
    .command(
      "$0 <file1> <file2>",
      "Deep merge two JSON files and sort keys alphabetically",
      (yargs) => {
        return yargs
          .positional("file1", {
            type: "string",
            description: "Path to the first JSON file (base)",
            demandOption: true,
          })
          .positional("file2", {
            type: "string",
            description:
              "Path to the second JSON file (overrides on conflict)",
            demandOption: true,
          });
      }
    )
    .help()
    .alias("h", "help")
    .strict()
    .parse();

  const [json1, json2] = await Promise.all([
    readJson(argv.file1 as string),
    readJson(argv.file2 as string),
  ]);

  const merged = deepMerge(json1 as any, json2 as any);
  const sorted = sortKeysDeep(merged);
  console.log(JSON.stringify(sorted, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
