#! /usr/bin/env bun
// ---
// description: Watch GitHub Actions workflow runs with desktop notifications
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { discoverRuns } from "./discovery";

async function main() {
  await yargs(hideBin(process.argv))
    .scriptName("ghw")
    .usage("$0 - Watch GitHub Actions workflow runs")
    .command(
      "$0",
      "Discover and display in-progress workflow runs",
      () => {},
      async () => {
        const { runs, branch, owner, repo } = await discoverRuns();
        console.log(
          `\nFound ${runs.length} run(s) on ${owner}/${repo}@${branch}:\n`,
        );
        console.log(JSON.stringify(runs, null, 2));
      },
    )
    .help()
    .alias("h", "help")
    .parseAsync();
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
