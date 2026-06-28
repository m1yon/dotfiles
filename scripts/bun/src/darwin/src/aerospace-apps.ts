import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface AerospaceApp {
  name: string;
  bundleId: string;
  workspace: string;
  startup: boolean;
  extraCommands: string[];
}

interface RawAerospaceApp {
  name: string;
  bundleId: string;
  workspace: string;
  startup?: boolean;
  extraCommands?: string[];
}

const RELATIVE_REGISTRY_PATH = join("dotfiles", "aerospace", "apps.json");

export function resolveDotfilesRoot(): string {
  const candidates = [
    process.env["NIX_CONFIG_DIR"],
    join(homedir(), "GitHub", "dotfiles"),
    process.cwd(),
  ].filter((candidate): candidate is string => Boolean(candidate));

  const root = candidates.find((candidate) =>
    existsSync(join(candidate, RELATIVE_REGISTRY_PATH)),
  );

  if (!root) {
    throw new Error(
      `Could not find ${RELATIVE_REGISTRY_PATH}. Set NIX_CONFIG_DIR to the dotfiles root.`,
    );
  }

  return root;
}

export function aerospaceAppsPath(root = resolveDotfilesRoot()): string {
  return join(root, RELATIVE_REGISTRY_PATH);
}

function asRecord(value: unknown, context: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${context} must be an object.`);
  }

  return value as Record<string, unknown>;
}

function stringField(
  record: Record<string, unknown>,
  key: keyof RawAerospaceApp,
  context: string,
): string {
  const value = record[key];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${context}.${key} must be a non-empty string.`);
  }

  return value;
}

function optionalBooleanField(
  record: Record<string, unknown>,
  key: keyof RawAerospaceApp,
  fallback: boolean,
  context: string,
): boolean {
  const value = record[key];
  if (value === undefined) return fallback;
  if (typeof value !== "boolean") {
    throw new Error(`${context}.${key} must be a boolean.`);
  }

  return value;
}

function optionalStringArrayField(
  record: Record<string, unknown>,
  key: keyof RawAerospaceApp,
  context: string,
): string[] {
  const value = record[key];
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
    throw new Error(`${context}.${key} must be an array of strings.`);
  }

  return value;
}

function parseApp(value: unknown, index: number): AerospaceApp {
  const context = `apps[${index}]`;
  const record = asRecord(value, context);

  return {
    name: stringField(record, "name", context),
    bundleId: stringField(record, "bundleId", context),
    workspace: stringField(record, "workspace", context),
    startup: optionalBooleanField(record, "startup", false, context),
    extraCommands: optionalStringArrayField(record, "extraCommands", context),
  };
}

export async function loadAerospaceApps(): Promise<AerospaceApp[]> {
  const registryPath = aerospaceAppsPath();
  const raw = asRecord(await Bun.file(registryPath).json(), registryPath);
  const apps = raw["apps"];

  if (!Array.isArray(apps)) {
    throw new Error(`${registryPath}.apps must be an array.`);
  }

  return apps.map(parseApp);
}
