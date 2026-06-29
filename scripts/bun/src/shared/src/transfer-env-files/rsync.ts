export interface CommandResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

export type CommandRunner = (argv: string[]) => Promise<CommandResult>;

export interface RsyncOptions {
  host: string;
  remoteRoot: string;
  localRoot: string;
  dryRun: boolean;
  overwrite: boolean;
}

export interface RsyncSummary {
  changedPaths: string[];
  transferredFiles: number | null;
  totalFileSize: string | null;
  totalTransferredFileSize: string | null;
  bytesSent: string | null;
  bytesReceived: string | null;
}

export interface RsyncResult {
  argv: string[];
  stdout: string;
  stderr: string;
  summary: RsyncSummary;
}

const EXCLUDE_FILTERS = [
  "**/.git/***",
  "**/node_modules/***",
  "**/.direnv/***",
  "**/.next/***",
  "**/dist/***",
  "**/build/***",
  "**/coverage/***",
  ".env.example",
  ".env.sample",
  ".env.template",
] as const;

const INCLUDE_FILTERS = ["*/", ".env", ".env.*"] as const;

function ensureTrailingSlash(path: string): string {
  return path.endsWith("/") ? path : `${path}/`;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function formatRemotePathForRsync(path: string): string {
  const withSlash = ensureTrailingSlash(path);
  if (/^[A-Za-z0-9_@%+=:,./~-]+$/.test(withSlash)) return withSlash;

  return shellQuote(withSlash);
}

function parseNumber(value: string): number {
  return Number(value.replace(/,/g, ""));
}

function parseStatNumber(output: string, labels: string[]): number | null {
  for (const label of labels) {
    const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const match = output.match(new RegExp(`${escaped}:\\s*([\\d,]+)`));
    if (match?.[1]) return parseNumber(match[1]);
  }

  return null;
}

function parseStatText(output: string, label: string): string | null {
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = output.match(new RegExp(`${escaped}:\\s*([^\\n]+)`));
  return match?.[1]?.trim() ?? null;
}

function parseChangedPaths(output: string): string[] {
  const paths: string[] = [];

  for (const line of output.split("\n")) {
    const match = line.match(/^[<>ch.*][^\s]*\s+(.+)$/);
    const path = match?.[1];
    if (!path) continue;

    const fileName = path.split("/").at(-1);
    if (fileName === ".env" || fileName?.startsWith(".env.")) {
      paths.push(path);
    }
  }

  return paths;
}

export async function runCommand(argv: string[]): Promise<CommandResult> {
  let proc: Bun.Subprocess<"pipe", "pipe", "pipe">;

  try {
    proc = Bun.spawn(argv, { stdout: "pipe", stderr: "pipe" });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to start ${argv[0]}: ${message}`);
  }

  const [exitCode, stdout, stderr] = await Promise.all([
    proc.exited,
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);

  return { exitCode, stdout, stderr };
}

export function buildRsyncArgv(options: RsyncOptions): string[] {
  const argv = [
    "rsync",
    "-a",
    "--prune-empty-dirs",
    "--itemize-changes",
    "--stats",
  ];

  if (options.dryRun) argv.push("--dry-run");
  if (!options.overwrite) argv.push("--ignore-existing");

  for (const pattern of EXCLUDE_FILTERS) {
    argv.push(`--exclude=${pattern}`);
  }

  for (const pattern of INCLUDE_FILTERS) {
    argv.push(`--include=${pattern}`);
  }

  argv.push("--exclude=*");
  argv.push(`${options.host}:${formatRemotePathForRsync(options.remoteRoot)}`);
  argv.push(ensureTrailingSlash(options.localRoot));

  return argv;
}

export function parseRsyncSummary(stdout: string, stderr: string): RsyncSummary {
  const output = `${stdout}\n${stderr}`;

  return {
    changedPaths: parseChangedPaths(output),
    transferredFiles: parseStatNumber(output, [
      "Number of regular files transferred",
      "Number of files transferred",
    ]),
    totalFileSize: parseStatText(output, "Total file size"),
    totalTransferredFileSize: parseStatText(
      output,
      "Total transferred file size",
    ),
    bytesSent: parseStatText(output, "Total bytes sent"),
    bytesReceived: parseStatText(output, "Total bytes received"),
  };
}

export async function runRsync(
  options: RsyncOptions,
  runner: CommandRunner = runCommand,
): Promise<RsyncResult> {
  const argv = buildRsyncArgv(options);
  const result = await runner(argv);
  const summary = parseRsyncSummary(result.stdout, result.stderr);

  if (result.exitCode !== 0) {
    const output = [result.stderr.trim(), result.stdout.trim()]
      .filter(Boolean)
      .join("\n");
    throw new Error(output ? `rsync failed:\n${output}` : "rsync failed.");
  }

  return {
    argv,
    stdout: result.stdout,
    stderr: result.stderr,
    summary,
  };
}
