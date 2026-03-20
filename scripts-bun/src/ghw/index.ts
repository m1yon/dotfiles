#! /usr/bin/env bun
// ---
// description: Watch GitHub Actions workflow runs with desktop notifications
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { discoverRuns } from "./discovery";
import { selectRun } from "./interactive";
import { watchRun, printSummary, formatDuration } from "./display";
import { notify } from "./notify";

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

        const selectedRun = await selectRun(runs);

        let result;
        try {
          result = await watchRun(owner, repo, selectedRun);
        } catch (error) {
          const message =
            error instanceof Error ? error.message : String(error);
          await notify(
            `ghw: ${selectedRun.name}`,
            `Error: ${message}`,
            "critical",
          );
          throw error;
        }

        const { run } = result;
        const conclusion = run.conclusion ?? "unknown";
        const duration = formatDuration(run.created_at, run.updated_at);

        const isSuccess = conclusion === "success";
        const label = isSuccess
          ? `Completed in ${duration}`
          : conclusion === "cancelled"
            ? `Cancelled in ${duration}`
            : `Failed in ${duration}`;

        await notify(
          `ghw: ${run.name}`,
          label,
          isSuccess ? "normal" : "critical",
        );

        printSummary(result);
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
