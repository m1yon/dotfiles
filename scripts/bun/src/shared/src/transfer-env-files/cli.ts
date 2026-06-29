import yargs from "yargs";
import { hideBin } from "yargs/helpers";

export interface CliOptions {
  host: string;
  remoteRoot?: string;
  localRoot?: string;
  dryRun: boolean;
  overwrite: boolean;
  verbose: boolean;
}

interface ParsedArgs {
  host?: unknown;
  remoteRoot?: unknown;
  localRoot?: unknown;
  dryRun?: unknown;
  overwrite?: unknown;
  verbose?: unknown;
}

function assertSafeText(value: string, label: string): void {
  if (value.length === 0) {
    throw new Error(`${label} cannot be empty.`);
  }

  if (/[\0\r\n]/.test(value)) {
    throw new Error(`${label} cannot contain control characters.`);
  }
}

function assertSafeHost(host: string): void {
  assertSafeText(host, "Host");

  if (host !== host.trim() || /\s/.test(host)) {
    throw new Error("Host cannot contain whitespace.");
  }

  if (host.startsWith("-")) {
    throw new Error("Host cannot start with '-'.");
  }

  if (host.includes("/")) {
    throw new Error("Host must be an SSH target, not a path or URL.");
  }
}

function optionalString(value: unknown, label: string): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string") {
    throw new Error(`${label} must be a string.`);
  }

  assertSafeText(value, label);
  return value;
}

function optionalBoolean(value: unknown): boolean {
  return value === true;
}

export async function parseCliArgs(argv: string[]): Promise<CliOptions> {
  const parsed = (await yargs(hideBin(argv))
    .scriptName("transfer-env-files")
    .usage("Usage: $0 <host> [options]")
    .command(
      "$0 <host>",
      "Copy project-local .env files from a remote GitHub workspace",
      (builder) =>
        builder.positional("host", {
          type: "string",
          description: "SSH target for the source machine",
          demandOption: true,
        }),
    )
    .option("remote-root", {
      type: "string",
      description: "Remote GitHub workspace root to scan",
    })
    .option("local-root", {
      type: "string",
      description: "Local GitHub workspace root to copy into",
    })
    .option("dry-run", {
      type: "boolean",
      default: false,
      description: "Show what would copy without writing files",
    })
    .option("overwrite", {
      type: "boolean",
      default: false,
      description: "Replace existing local env files",
    })
    .option("verbose", {
      type: "boolean",
      default: false,
      description: "Show resolved roots and the generated rsync command",
    })
    .help()
    .alias("h", "help")
    .strict()
    .parse()) as ParsedArgs;

  if (typeof parsed.host !== "string") {
    throw new Error("Host is required.");
  }

  assertSafeHost(parsed.host);

  const remoteRoot = optionalString(parsed.remoteRoot, "Remote root");
  const localRoot = optionalString(parsed.localRoot, "Local root");

  if (remoteRoot?.startsWith("-")) {
    throw new Error("Remote root cannot start with '-'.");
  }

  return {
    host: parsed.host,
    remoteRoot,
    localRoot,
    dryRun: optionalBoolean(parsed.dryRun),
    overwrite: optionalBoolean(parsed.overwrite),
    verbose: optionalBoolean(parsed.verbose),
  };
}
