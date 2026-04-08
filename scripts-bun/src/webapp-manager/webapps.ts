import { join, dirname } from "node:path";

export interface WebApp {
  name: string;
  url: string;
  bind?: string;
  workspace?: string;
}

function getWebappsPath(): string {
  // Resolve relative to dotfiles repo: dotfiles/webapps.json
  // scripts-bun/ is at dotfiles/scripts-bun/, so go up one level
  const scriptsBunDir = join(import.meta.dir, "..", "..");
  return join(dirname(scriptsBunDir), "dotfiles", "webapps.json");
}

export async function loadWebapps(
  path: string = getWebappsPath(),
): Promise<WebApp[]> {
  const file = Bun.file(path);
  if (!(await file.exists())) return [];
  const text = await file.text();
  return JSON.parse(text) as WebApp[];
}

export async function saveWebapps(
  webapps: WebApp[],
  path: string = getWebappsPath(),
): Promise<void> {
  await Bun.write(path, JSON.stringify(webapps, null, 2) + "\n");
}
