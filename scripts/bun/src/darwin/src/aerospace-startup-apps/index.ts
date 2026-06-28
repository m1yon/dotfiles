#!/usr/bin/env bun
// ---
// description: Launch AeroSpace startup apps while keeping focus on workspace 1
// ---
import { existsSync } from "node:fs";
import { loadAerospaceApps } from "../aerospace-apps";

interface CommandResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

const focusWorkspace = process.env["AEROSPACE_STARTUP_WORKSPACE"] ?? "1";
const timeoutMs = numberFromEnv("AEROSPACE_STARTUP_TIMEOUT_MS", 30_000);
const settleMs = numberFromEnv("AEROSPACE_STARTUP_SETTLE_MS", 1_500);
const pollMs = numberFromEnv("AEROSPACE_STARTUP_POLL_MS", 100);
const aerospace = resolveAerospaceBinary();

function numberFromEnv(name: string, fallback: number): number {
  const value = process.env[name];
  if (!value) return fallback;

  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function resolveAerospaceBinary(): string {
  const configured = process.env["AEROSPACE"];
  if (configured) return configured;

  const profileBinary = `/etc/profiles/per-user/${process.env["USER"]}/bin/aerospace`;
  return existsSync(profileBinary) ? profileBinary : "aerospace";
}

async function run(command: string[]): Promise<CommandResult> {
  const proc = Bun.spawn(command, {
    stdout: "pipe",
    stderr: "pipe",
  });

  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);

  return { exitCode, stdout, stderr };
}

async function launchApps(bundleIds: string[]): Promise<void> {
  await Promise.all(
    bundleIds.map((bundleId) =>
      run(["/usr/bin/open", "-g", "-j", "-b", bundleId]),
    ),
  );
}

async function windowIdsForApp(bundleId: string): Promise<string[]> {
  const result = await run([
    aerospace,
    "list-windows",
    "--monitor",
    "all",
    "--app-bundle-id",
    bundleId,
    "--format",
    "%{window-id}",
  ]);

  if (result.exitCode !== 0) return [];

  return result.stdout
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
}

async function appHasWindow(bundleId: string): Promise<boolean> {
  const windowIds = await windowIdsForApp(bundleId);
  return windowIds.length > 0;
}

async function restoreFocus(): Promise<void> {
  await run([aerospace, "workspace", focusWorkspace]);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main(): Promise<void> {
  const seenBundleIds = new Set<string>();
  const startedAt = Date.now();
  let allAppsSeenAt: number | null = null;
  const startupAppBundleIds = (await loadAerospaceApps())
    .filter((app) => app.startup)
    .map((app) => app.bundleId);

  await restoreFocus();
  await launchApps(startupAppBundleIds);

  while (Date.now() - startedAt < timeoutMs) {
    const detections = await Promise.all(
      startupAppBundleIds.map(appHasWindow),
    );

    detections.forEach((detected, index) => {
      const bundleId = startupAppBundleIds[index];
      if (detected && bundleId) seenBundleIds.add(bundleId);
    });

    await restoreFocus();

    const allAppsSeen = seenBundleIds.size === startupAppBundleIds.length;
    if (allAppsSeen && allAppsSeenAt === null) {
      allAppsSeenAt = Date.now();
    }

    if (allAppsSeenAt !== null && Date.now() - allAppsSeenAt >= settleMs) {
      break;
    }

    await sleep(pollMs);
  }

  await restoreFocus();
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
});
