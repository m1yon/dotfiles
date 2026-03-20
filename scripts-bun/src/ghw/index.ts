#! /usr/bin/env bun
// ---
// description: Watch GitHub Actions workflow runs with desktop notifications
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { discoverRuns } from "./discovery";
import { selectRun } from "./interactive";
import { watchRun } from "./display";

async function main() {
  await yargs(hideBin(process.argv))
    .scriptName("ghw")
    .usage("$0 - Watch GitHub Actions workflow runs")
    .command(
      "$0",
      "Watch a GitHub Actions workflow run",
      () => {},
      async () => {
        const { runs, branch, owner, repo } = await discoverRuns();
        console.log(
          `Found ${runs.length} run(s) on ${owner}/${repo}@${branch}\n`,
        );

        const run = await selectRun(runs);
        const result = await watchRun(owner, repo, run);

        console.log(`\n${result.run.html_url}`);
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
