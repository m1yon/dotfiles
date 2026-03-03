#!/usr/bin/env bun
// ---
// description: Recursively find .env files and scp them to a remote host preserving paths
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { Glob } from "bun";
import { resolve } from "path";

async function findEnvFiles(directory: string): Promise<string[]> {
  const glob = new Glob("**/*.env");
  const files: string[] = [];
  for await (const match of glob.scan({ cwd: directory, dot: true })) {
    files.push(match);
  }
  return files.sort();
}

async function runWithTimeout(
  cmd: string[],
  timeoutSecs: number
): Promise<number> {
  const proc = Bun.spawn(cmd, {
    stdout: "inherit",
    stderr: "inherit",
  });

  let timer: Timer;
  const result = await Promise.race([
    proc.exited,
    new Promise<never>((_, reject) => {
      timer = setTimeout(() => {
        proc.kill();
        reject(new Error(`Command timed out after ${timeoutSecs}s: ${cmd.join(" ")}`));
      }, timeoutSecs * 1000);
    }),
  ]);
  clearTimeout(timer!);

  return result;
}

async function scpFile(
  localPath: string,
  target: string,
  remotePath: string,
  dryRun: boolean,
  timeoutSecs: number
): Promise<void> {
  const dest = `${target}:${remotePath}`;
  const remoteDir = remotePath.substring(0, remotePath.lastIndexOf("/"));

  if (dryRun) {
    console.log(`  mkdir -p ${remoteDir}`);
    console.log(`  scp -> ${dest}`);
    return;
  }

  // Ensure remote directory exists
  console.log(`  mkdir -p ${target}:${remoteDir}`);
  const mkdirExit = await runWithTimeout(
    ["ssh", target, "mkdir", "-p", remoteDir],
    timeoutSecs
  );
  if (mkdirExit !== 0) {
    throw new Error(
      `Failed to create remote directory ${remoteDir} (exit code ${mkdirExit})`
    );
  }

  console.log(`  scp -> ${dest}`);
  const scpExit = await runWithTimeout(
    ["scp", localPath, dest],
    timeoutSecs
  );
  if (scpExit !== 0) {
    throw new Error(
      `Failed to scp ${localPath} to ${dest} (exit code ${scpExit})`
    );
  }
}

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .usage("Usage: $0 <directory> <target>")
    .command(
      "$0 <directory> <target>",
      "Recursively find *.env files and scp them to a remote host at the same absolute path",
      (yargs) => {
        return yargs
          .positional("directory", {
            type: "string",
            description: "Local directory to search for .env files",
            demandOption: true,
          })
          .positional("target", {
            type: "string",
            description: "SCP target (e.g. user@host)",
            demandOption: true,
          });
      }
    )
    .option("dry-run", {
      alias: "n",
      type: "boolean",
      description: "Show what would be transferred without doing it",
      default: false,
    })
    .option("timeout", {
      alias: "t",
      type: "number",
      description: "Timeout in seconds per command",
      default: 30,
    })
    .help()
    .alias("h", "help")
    .strict()
    .parse();

  const directory = resolve(argv.directory as string);
  const target = argv.target as string;
  const dryRun = argv.dryRun as boolean;
  const timeoutSecs = argv.timeout as number;

  const files = await findEnvFiles(directory);

  if (files.length === 0) {
    console.log(`No *.env files found in ${directory}`);
    process.exit(0);
  }

  console.log(`Found ${files.length} .env file(s) in ${directory}:\n`);

  for (let i = 0; i < files.length; i++) {
    const file = files[i]!;
    const localPath = resolve(directory, file);
    console.log(`[${i + 1}/${files.length}] ${file}`);
    await scpFile(localPath, target, localPath, dryRun, timeoutSecs);
  }

  console.log(`\nDone. Transferred ${files.length} file(s).`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
