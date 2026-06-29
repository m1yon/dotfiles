import { mkdir } from "node:fs/promises";
import { parseCliArgs } from "./cli.ts";
import {
  assertLocalTransferTools,
  assertRemoteRsync,
  assertSshReachable,
  resolveLocalRoot,
  resolveRemoteRoot,
} from "./roots.ts";
import { buildRsyncArgv, runRsync, type RsyncSummary } from "./rsync.ts";

function quoteForDisplay(value: string): string {
  if (/^[A-Za-z0-9_@%+=:,./~-]+$/.test(value)) return value;
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function formatCommand(argv: string[]): string {
  return argv.map(quoteForDisplay).join(" ");
}

function formatPathList(paths: string[]): string {
  const visible = paths.slice(0, 50);
  const lines = visible.map((path) => `  ${path}`);
  const remaining = paths.length - visible.length;

  if (remaining > 0) {
    lines.push(`  ... and ${remaining} more`);
  }

  return lines.join("\n");
}

function printSummary(summary: RsyncSummary, dryRun: boolean): void {
  const verb = dryRun ? "would be copied" : "copied";
  const count =
    summary.changedPaths.length > 0
      ? summary.changedPaths.length
      : (summary.transferredFiles ?? 0);

  if (count === 0) {
    console.log(
      dryRun
        ? "No missing env files would be copied."
        : "No missing env files were copied.",
    );
  } else {
    console.log(`${count} env file(s) ${verb}.`);
  }

  if (summary.changedPaths.length > 0) {
    console.log(formatPathList(summary.changedPaths));
  }

  if (dryRun && summary.totalFileSize) {
    console.log(`Total matching file size: ${summary.totalFileSize}`);
  } else if (summary.totalTransferredFileSize ?? summary.totalFileSize) {
    console.log(
      `Total transferred file size: ${
        summary.totalTransferredFileSize ?? summary.totalFileSize
      }`,
    );
  }
}

export async function runCli(argv: string[]): Promise<void> {
  const options = await parseCliArgs(argv);

  await assertLocalTransferTools();
  await assertSshReachable(options.host);
  await assertRemoteRsync(options.host);

  const [localRoot, remoteRoot] = await Promise.all([
    resolveLocalRoot(options.localRoot),
    resolveRemoteRoot(options.host, options.remoteRoot),
  ]);

  await mkdir(localRoot, { recursive: true });

  const rsyncOptions = {
    host: options.host,
    remoteRoot,
    localRoot,
    dryRun: options.dryRun,
    overwrite: options.overwrite,
  };

  if (options.verbose) {
    console.log(`Remote root: ${options.host}:${remoteRoot}`);
    console.log(`Local root: ${localRoot}`);
    console.log(`Overwrite existing env files: ${options.overwrite ? "yes" : "no"}`);
    console.log(`Rsync command: ${formatCommand(buildRsyncArgv(rsyncOptions))}`);
  }

  const result = await runRsync(rsyncOptions);
  printSummary(result.summary, options.dryRun);

  if (options.dryRun) {
    console.log("Dry run only; no files were written.");
  }
}
