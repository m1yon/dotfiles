import { join } from "node:path";

export interface WebApp {
  name: string;
  url: string;
  bind?: string;
  workspace?: string;
}

export function getWebappsPath(): string {
  const nixConfigDir = process.env["NIX_CONFIG_DIR"];
  if (!nixConfigDir) {
    throw new Error(
      "NIX_CONFIG_DIR is not set. Set it to your dotfiles root.",
    );
  }
  return join(nixConfigDir, "dotfiles", "webapps.json");
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
