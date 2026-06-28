#!/usr/bin/env bun
// ---
// description: Generate AeroSpace app routing rules from dotfiles/aerospace/apps.json
// ---
import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import {
  type AerospaceApp,
  aerospaceAppsPath,
  loadAerospaceApps,
  resolveDotfilesRoot,
} from "../aerospace-apps";

const START_MARKER = "# BEGIN generated app rules from dotfiles/aerospace/apps.json";
const END_MARKER = "# END generated app rules from dotfiles/aerospace/apps.json";

function tomlString(value: string): string {
  return JSON.stringify(value);
}

function tomlArray(values: string[]): string {
  return `[${values.map(tomlString).join(", ")}]`;
}

function routeCommands(app: AerospaceApp): string[] {
  return [`move-node-to-workspace ${app.workspace}`, ...app.extraCommands];
}

function appRule(app: AerospaceApp): string {
  const commands = routeCommands(app);
  const runValue =
    commands.length === 1 ? tomlString(commands[0] ?? "") : tomlArray(commands);

  return [
    `# ${app.name}`,
    "[[on-window-detected]]",
    `if.app-id = ${tomlString(app.bundleId)}`,
    `run = ${runValue}`,
  ].join("\n");
}

function generatedBlock(apps: AerospaceApp[]): string {
  return [
    START_MARKER,
    "# Edit the registry, then run: cd scripts/bun && bun run aerospace:generate",
    ...apps.map(appRule),
    END_MARKER,
  ].join("\n\n");
}

function markerPattern(): RegExp {
  return new RegExp(
    `${escapeRegExp(START_MARKER)}[\\s\\S]*?${escapeRegExp(END_MARKER)}`,
  );
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function main(): Promise<void> {
  const root = resolveDotfilesRoot();
  const configPath = join(root, "dotfiles", "aerospace", "aerospace.toml");
  const apps = await loadAerospaceApps();
  const config = await readFile(configPath, "utf8");
  const pattern = markerPattern();

  if (!pattern.test(config)) {
    throw new Error(
      `${configPath} is missing generated app rule markers for ${aerospaceAppsPath(root)}.`,
    );
  }

  const nextConfig = config.replace(pattern, generatedBlock(apps));

  if (nextConfig === config) {
    console.log("AeroSpace app rules are already up to date.");
    return;
  }

  await writeFile(configPath, nextConfig);
  console.log(`Updated ${configPath}`);
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
});
