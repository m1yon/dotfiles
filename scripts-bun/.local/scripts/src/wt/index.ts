#!/usr/bin/env bun
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { existsSync, readdirSync } from "node:fs";
import { mkdir, rm, rmdir } from "node:fs/promises";
import { basename, join } from "node:path";

class WtError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "WtError";
  }
}

/** Run a command and return { exitCode, stdout, stderr } */
async function run(
  cmd: string[],
  opts?: { cwd?: string }
): Promise<{ exitCode: number; stdout: string; stderr: string }> {
  const proc = Bun.spawn(cmd, {
    stdout: "pipe",
    stderr: "pipe",
    cwd: opts?.cwd,
  });
  const [exitCode, stdout, stderr] = await Promise.all([
    proc.exited,
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  return { exitCode, stdout: stdout.trim(), stderr: stderr.trim() };
}

/** Run a command, throwing on non-zero exit */
async function exec(
  cmd: string[],
  opts?: { cwd?: string }
): Promise<string> {
  const result = await run(cmd, opts);
  if (result.exitCode !== 0) {
    throw new WtError(
      `Command failed: ${cmd.join(" ")}\n${result.stderr || result.stdout}`
    );
  }
  return result.stdout;
}

async function getRepoRoot(): Promise<string> {
  const result = await run(["git", "rev-parse", "--show-toplevel"]);
  if (result.exitCode !== 0 || !result.stdout) {
    throw new WtError("Not inside a git repository.");
  }
  return result.stdout;
}

async function getCurrentBranch(): Promise<string> {
  const result = await run(["git", "branch", "--show-current"]);
  if (result.exitCode !== 0 || !result.stdout) {
    throw new WtError(
      "Could not determine current branch (Detached HEAD?)."
    );
  }
  return result.stdout;
}

async function branchExists(name: string): Promise<boolean> {
  const result = await run([
    "git",
    "show-ref",
    "--verify",
    "--quiet",
    `refs/heads/${name}`,
  ]);
  return result.exitCode === 0;
}

// ---------------------------------------------------------
// SUBCOMMAND: CREATE
// ---------------------------------------------------------
async function handleCreate(): Promise<void> {
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");
  const currentBranch = await getCurrentBranch();

  await mkdir(worktreesDir, { recursive: true });

  // Find the next available index
  let index = 1;
  let branch: string;
  let targetDir: string;

  while (true) {
    const candidate = `${currentBranch}-wt-${index}`;
    targetDir = join(worktreesDir, candidate);

    const [exists, dirExists] = await Promise.all([
      branchExists(candidate),
      Promise.resolve(existsSync(targetDir)),
    ]);

    if (exists || dirExists) {
      index++;
    } else {
      branch = candidate;
      break;
    }
  }

  console.log(`🌳 Creating worktree: ${branch}`);

  const result = await run([
    "git",
    "worktree",
    "add",
    targetDir!,
    "-b",
    branch!,
  ]);
  if (result.exitCode !== 0) {
    throw new WtError(`Failed to create worktree.\n${result.stderr}`);
  }

  // Copy .env files
  console.log("📄 Copying .env files...");
  const envFiles = readdirSync(repoRoot).filter((f) => f.startsWith(".env"));
  for (const envFile of envFiles) {
    const src = join(repoRoot, envFile);
    const dest = join(targetDir!, envFile);
    await Bun.write(dest, Bun.file(src));
  }

  // Detect bun project and install dependencies
  const hasBunLock =
    existsSync(join(repoRoot, "bun.lockb")) ||
    existsSync(join(repoRoot, "bun.lock"));

  if (hasBunLock) {
    console.log("🥯 Bun project detected. Installing dependencies...");
    const install = await run(["bun", "install"], { cwd: targetDir! });
    if (install.stdout) console.log(install.stdout);
    if (install.stderr) console.error(install.stderr);
  }

  console.log("✅ Ready!");
  console.log(`   cd ${targetDir!}`);
}

// ---------------------------------------------------------
// SUBCOMMAND: RM
// ---------------------------------------------------------
async function handleRm(branch: string): Promise<void> {
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");
  const targetDir = join(worktreesDir, branch);

  if (existsSync(targetDir)) {
    console.log("🔥 Removing worktree folder...");
    await exec(["git", "worktree", "remove", targetDir, "--force"]);
  } else {
    console.log(
      `⚠️  Worktree folder not found at: ${targetDir} (checking branch only)`
    );
  }

  if (await branchExists(branch)) {
    console.log(`🔥 Deleting git branch '${branch}'...`);
    const out = await exec(["git", "branch", "-D", branch]);
    if (out) console.log(out);
  } else {
    console.log(`⚠️  Branch '${branch}' not found.`);
  }

  console.log(`✅ Cleanup complete for '${branch}'.`);
}

// ---------------------------------------------------------
// SUBCOMMAND: CLEAN
// ---------------------------------------------------------
async function handleClean(): Promise<void> {
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");

  if (!existsSync(worktreesDir)) {
    console.log("✨ No worktrees found to clean.");
    return;
  }

  console.log("🧹 Cleaning all worktrees in .worktrees/...");

  const entries = readdirSync(worktreesDir, { withFileTypes: true });
  let needsPrune = false;

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const branchName = entry.name;
    const target = join(worktreesDir, branchName);

    // 1. Remove the worktree (force in case of uncommitted changes)
    const result = await run([
      "git",
      "worktree",
      "remove",
      "--force",
      target,
    ]);
    if (result.exitCode !== 0) {
      // Fallback: manually remove the directory
      await rm(target, { recursive: true, force: true });
      needsPrune = true;
    }

    // 2. Delete the branch (ignore errors if already gone)
    await run(["git", "branch", "-D", branchName]);

    console.log(`   🔥 Removed: ${branchName}`);
  }

  if (needsPrune) {
    await run(["git", "worktree", "prune"]);
  }

  // Remove the parent folder if it's now empty
  try {
    await rmdir(worktreesDir);
  } catch {
    // Directory not empty or already gone — that's fine
  }

  console.log("✨ All clear.");
}

// ---------------------------------------------------------
// CLI
// ---------------------------------------------------------
async function main() {
  await yargs(hideBin(process.argv))
    .scriptName("wt")
    .usage("Usage: $0 <command> [args]")
    .command(
      "create",
      "Create a new worktree (auto-named based on current branch)",
      () => {},
      async () => {
        await handleCreate();
      }
    )
    .command(
      "rm <branch>",
      "Remove a single worktree and its branch",
      (yargs) =>
        yargs.positional("branch", {
          type: "string",
          description: "Branch name to remove",
          demandOption: true,
        }),
      async (argv) => {
        await handleRm(argv.branch as string);
      }
    )
    .command(
      "clean",
      "Remove all worktrees in .worktrees/",
      () => {},
      async () => {
        await handleClean();
      }
    )
    .example("$0 create", "Create worktree named <branch>-wt-1")
    .example("$0 rm my-branch", "Remove worktree and branch 'my-branch'")
    .example("$0 clean", "Remove all worktrees")
    .demandCommand(1, "Please specify a command.")
    .strict()
    .help()
    .alias("h", "help")
    .parse();
}

main().catch((error) => {
  if (error instanceof WtError) {
    console.error(`❌ ${error.message}`);
    process.exit(1);
  }
  console.error("Unexpected error:", error);
  process.exit(1);
});
