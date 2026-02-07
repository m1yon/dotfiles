#!/usr/bin/env bun
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import { select, confirm } from "@inquirer/prompts";
import { existsSync, readdirSync } from "node:fs";
import { mkdir, rm, rmdir } from "node:fs/promises";
import { join } from "node:path";

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

  console.log("✅ Ready! Spawning subshell...");

  const shell = process.env.SHELL || "/bin/sh";
  const subshell = Bun.spawn([shell], {
    cwd: targetDir!,
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
    env: { ...process.env, WT_WORKTREE: branch! },
  });
  const code = await subshell.exited;
  process.exit(code);
}

// ---------------------------------------------------------
// SUBCOMMAND: LIST
// ---------------------------------------------------------

interface WorktreeEntry {
  path: string;
  commit: string;
  branch: string | null;
  bare: boolean;
}

function parseWorktreeList(output: string): WorktreeEntry[] {
  const entries: WorktreeEntry[] = [];
  const blocks = output.split("\n\n").filter(Boolean);
  for (const block of blocks) {
    const lines = block.split("\n");
    const pathLine = lines.find((l) => l.startsWith("worktree "));
    const commitLine = lines.find((l) => l.startsWith("HEAD "));
    const branchLine = lines.find((l) => l.startsWith("branch "));
    const isBare = lines.some((l) => l.trim() === "bare");
    if (!pathLine) continue;
    entries.push({
      path: pathLine.replace("worktree ", ""),
      commit: commitLine ? commitLine.replace("HEAD ", "").slice(0, 8) : "",
      branch: branchLine
        ? branchLine.replace("branch ", "").replace("refs/heads/", "")
        : null,
      bare: isBare,
    });
  }
  return entries;
}

async function handleList(): Promise<void> {
  const output = await exec(["git", "worktree", "list", "--porcelain"]);
  const entries = parseWorktreeList(output);

  if (entries.length === 0) {
    console.log("No worktrees found.");
    return;
  }

  const repoRoot = await getRepoRoot();
  const currentBranch = await getCurrentBranch();

  for (const entry of entries) {
    const rel = entry.path.startsWith(repoRoot)
      ? entry.path.slice(repoRoot.length + 1) || "."
      : entry.path;
    const branchLabel = entry.branch ?? "(detached)";
    const current = entry.branch === currentBranch ? " *" : "";
    console.log(`  ${entry.commit}  ${branchLabel}${current}\t${rel}`);
  }
}

// ---------------------------------------------------------
// SUBCOMMAND: RM
// ---------------------------------------------------------
async function pickWorktreeBranch(): Promise<string> {
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");

  if (!existsSync(worktreesDir)) {
    throw new WtError("No .worktrees/ directory found.");
  }

  const entries = readdirSync(worktreesDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);

  if (entries.length === 0) {
    throw new WtError("No worktrees found in .worktrees/.");
  }

  return select({
    message: "Select a worktree to remove",
    choices: entries.map((name) => ({ name, value: name })),
  });
}

async function handleRm(branch: string | undefined): Promise<void> {
  const resolvedBranch = branch ?? (await pickWorktreeBranch());
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");
  const targetDir = join(worktreesDir, resolvedBranch);

  if (existsSync(targetDir)) {
    console.log("🔥 Removing worktree folder...");
    await exec(["git", "worktree", "remove", targetDir, "--force"]);
  } else {
    console.log(
      `⚠️  Worktree folder not found at: ${targetDir} (checking branch only)`
    );
  }

  if (await branchExists(resolvedBranch)) {
    console.log(`🔥 Deleting git branch '${resolvedBranch}'...`);
    const out = await exec(["git", "branch", "-D", resolvedBranch]);
    if (out) console.log(out);
  } else {
    console.log(`⚠️  Branch '${resolvedBranch}' not found.`);
  }

  console.log(`✅ Cleanup complete for '${resolvedBranch}'.`);
}

// ---------------------------------------------------------
// SUBCOMMAND: CLEAN
// ---------------------------------------------------------
async function handleClean(force: boolean): Promise<void> {
  const repoRoot = await getRepoRoot();
  const worktreesDir = join(repoRoot, ".worktrees");

  if (!existsSync(worktreesDir)) {
    console.log("✨ No worktrees found to clean.");
    return;
  }

  const entries = readdirSync(worktreesDir, { withFileTypes: true }).filter(
    (e) => e.isDirectory()
  );

  if (entries.length === 0) {
    console.log("✨ No worktrees found to clean.");
    return;
  }

  console.log("The following worktrees will be removed:");
  for (const entry of entries) {
    console.log(`  - ${entry.name}`);
  }

  if (!force) {
    const confirmed = await confirm({
      message: `Remove ${entries.length} worktree${entries.length > 1 ? "s" : ""}?`,
      default: false,
    });
    if (!confirmed) {
      console.log("Aborted.");
      return;
    }
  }

  console.log("🧹 Cleaning all worktrees in .worktrees/...");
  let needsPrune = false;

  for (const entry of entries) {
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
      "rm [branch]",
      "Remove a single worktree and its branch (interactive if no branch given)",
      (yargs) =>
        yargs.positional("branch", {
          type: "string",
          description: "Branch name to remove",
        }),
      async (argv) => {
        await handleRm(argv.branch as string | undefined);
      }
    )
    .command(
      "clean",
      "Remove all worktrees in .worktrees/",
      (yargs) =>
        yargs.option("force", {
          alias: "f",
          type: "boolean",
          description: "Skip confirmation prompt",
          default: false,
        }),
      async (argv) => {
        await handleClean(argv.force);
      }
    )
    .command(
      ["list", "ls"],
      "List all worktrees",
      () => {},
      async () => {
        await handleList();
      }
    )
    .example("$0 create", "Create worktree named <branch>-wt-1")
    .example("$0 rm", "Interactively select a worktree to remove")
    .example("$0 rm my-branch", "Remove worktree and branch 'my-branch'")
    .example("$0 list", "List all worktrees")
    .example("$0 clean", "Remove all worktrees (with confirmation)")
    .example("$0 clean --force", "Remove all worktrees without confirmation")
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
