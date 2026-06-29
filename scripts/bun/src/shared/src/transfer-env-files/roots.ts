import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { stat } from "node:fs/promises";
import { runCommand, type CommandRunner } from "./rsync.ts";

const LOCAL_ROOT_CANDIDATES = ["GitHub", "github"] as const;
const REMOTE_ROOT_CANDIDATES = ["~/GitHub", "~/github"] as const;
const SSH_OPTIONS = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=10"] as const;

async function isDirectory(path: string): Promise<boolean> {
  try {
    return (await stat(path)).isDirectory();
  } catch {
    return false;
  }
}

function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function quoteRemotePath(path: string): string {
  if (path === "~") return "~";
  if (path.startsWith("~/")) {
    const rest = path.slice(2);
    return rest.length === 0 ? "~/" : `~/${shellQuote(rest)}`;
  }

  return shellQuote(path);
}

function trimOutput(result: { stdout: string; stderr: string }): string {
  return [result.stderr.trim(), result.stdout.trim()].filter(Boolean).join("\n");
}

async function assertCommandSucceeds(
  argv: string[],
  failureMessage: string,
  runner: CommandRunner,
): Promise<void> {
  const result = await runner(argv);
  if (result.exitCode === 0) return;

  const details = trimOutput(result);
  throw new Error(details ? `${failureMessage}\n${details}` : failureMessage);
}

async function resolveRemotePath(
  host: string,
  path: string,
  runner: CommandRunner,
): Promise<string | null> {
  const command = `cd ${quoteRemotePath(path)} && pwd -P`;
  const result = await runner(["ssh", ...SSH_OPTIONS, host, command]);

  if (result.exitCode !== 0) return null;

  const root = result.stdout.trim().split("\n").filter(Boolean).at(-1);
  return root ?? null;
}

export async function assertLocalTransferTools(
  runner: CommandRunner = runCommand,
): Promise<void> {
  await assertCommandSucceeds(
    ["ssh", "-V"],
    "ssh is required but failed to run.",
    runner,
  );
  await assertCommandSucceeds(
    ["rsync", "--version"],
    "rsync is required locally. Add pkgs.rsync declaratively and rebuild.",
    runner,
  );
}

export async function assertSshReachable(
  host: string,
  runner: CommandRunner = runCommand,
): Promise<void> {
  await assertCommandSucceeds(
    ["ssh", ...SSH_OPTIONS, host, "true"],
    `Could not reach ${host} over SSH.`,
    runner,
  );
}

export async function assertRemoteRsync(
  host: string,
  runner: CommandRunner = runCommand,
): Promise<void> {
  await assertCommandSucceeds(
    ["ssh", ...SSH_OPTIONS, host, "command -v rsync >/dev/null 2>&1"],
    `rsync is required on ${host}. Add pkgs.rsync declaratively there and rebuild.`,
    runner,
  );
}

export async function resolveLocalRoot(input?: string): Promise<string> {
  if (input) return resolve(expandHome(input));

  for (const candidate of LOCAL_ROOT_CANDIDATES) {
    const path = join(homedir(), candidate);
    if (await isDirectory(path)) return path;
  }

  return join(homedir(), LOCAL_ROOT_CANDIDATES[0]);
}

export async function resolveRemoteRoot(
  host: string,
  input?: string,
  runner: CommandRunner = runCommand,
): Promise<string> {
  if (input) {
    const root = await resolveRemotePath(host, input, runner);
    if (root) return root;

    throw new Error(`Remote root does not exist or is not a directory: ${input}`);
  }

  for (const candidate of REMOTE_ROOT_CANDIDATES) {
    const root = await resolveRemotePath(host, candidate, runner);
    if (root) return root;
  }

  throw new Error(
    `Could not find a remote GitHub workspace on ${host}. Tried ~/GitHub and ~/github; pass --remote-root to choose one explicitly.`,
  );
}
