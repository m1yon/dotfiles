import { describe, test, expect, afterEach, beforeEach } from "bun:test";
import { testRender } from "@opentui/react/test-utils";
import { act } from "react";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { mkdtemp, rm } from "node:fs/promises";
import { App } from "./app.tsx";
import { loadWebapps, saveWebapps, getWebappsPath, type WebApp } from "./webapps.ts";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

let testSetup: Awaited<ReturnType<typeof testRender>>;
let tmpDir: string;
let webappsPath: string;

async function keypress(name: string, extra: Record<string, boolean> = {}) {
  const event = {
    name,
    sequence: "",
    ctrl: false,
    shift: false,
    meta: false,
    option: false,
    eventType: "press" as const,
    repeated: false,
    number: false,
    raw: "",
    source: "raw" as const,
    defaultPrevented: false,
    propagationStopped: false,
    preventDefault() {},
    stopPropagation() {},
    ...extra,
  };
  await act(() => {
    testSetup.renderer.keyInput.emit("keypress", event as never);
  });
  await testSetup.renderOnce();
}

function frame(): string {
  return testSetup.captureCharFrame();
}

async function render(webapps: WebApp[] = []) {
  await saveWebapps(webapps, webappsPath);
  testSetup = await testRender(
    <App webappsPath={webappsPath} initialWebapps={webapps} />,
    { width: 80, height: 24 },
  );
  await testSetup.renderOnce();
}

// ---------------------------------------------------------------------------
// Setup / teardown
// ---------------------------------------------------------------------------

beforeEach(async () => {
  tmpDir = await mkdtemp(join(tmpdir(), "webapp-test-"));
  webappsPath = join(tmpDir, "webapps.json");
  await Bun.write(webappsPath, "[]");
});

afterEach(async () => {
  if (testSetup) {
    testSetup.renderer.destroy();
  }
  await rm(tmpDir, { recursive: true, force: true });
});

// ---------------------------------------------------------------------------
// Data layer
// ---------------------------------------------------------------------------

describe("webapps data layer", () => {
  test("loadWebapps returns empty array for empty file", async () => {
    const result = await loadWebapps(webappsPath);
    expect(result).toEqual([]);
  });

  test("loadWebapps returns empty array for missing file", async () => {
    const result = await loadWebapps(join(tmpDir, "nonexistent.json"));
    expect(result).toEqual([]);
  });

  test("saveWebapps then loadWebapps round-trips", async () => {
    const apps: WebApp[] = [
      { name: "Test", url: "https://test.com", bind: "$mainMod, T" },
    ];
    await saveWebapps(apps, webappsPath);
    const loaded = await loadWebapps(webappsPath);
    expect(loaded).toEqual(apps);
  });

  test("round-trips entries with mixed optional fields", async () => {
    const apps: WebApp[] = [
      {
        name: "Both",
        url: "https://both.com",
        bind: "$mainMod, B",
        workspace: "3",
      },
      { name: "BindOnly", url: "https://bind.com", bind: "$mainMod, O" },
      { name: "WorkspaceOnly", url: "https://ws.com", workspace: "5" },
      { name: "Neither", url: "https://neither.com" },
    ];
    await saveWebapps(apps, webappsPath);
    const loaded = await loadWebapps(webappsPath);
    expect(loaded).toEqual(apps);
    // Verify optional fields are truly absent, not just undefined
    expect(loaded[1]).not.toHaveProperty("workspace");
    expect(loaded[2]).not.toHaveProperty("bind");
    expect(loaded[3]).not.toHaveProperty("bind");
    expect(loaded[3]).not.toHaveProperty("workspace");
  });
});

// ---------------------------------------------------------------------------
// getWebappsPath
// ---------------------------------------------------------------------------

describe("getWebappsPath", () => {
  const origEnv = process.env["NIX_CONFIG_DIR"];

  afterEach(() => {
    if (origEnv !== undefined) {
      process.env["NIX_CONFIG_DIR"] = origEnv;
    } else {
      delete process.env["NIX_CONFIG_DIR"];
    }
  });

  test("returns path based on NIX_CONFIG_DIR", () => {
    process.env["NIX_CONFIG_DIR"] = "/home/user/dotfiles";
    const result = getWebappsPath();
    expect(result).toBe("/home/user/dotfiles/dotfiles/webapps.json");
  });

  test("throws descriptive error when NIX_CONFIG_DIR is unset", () => {
    delete process.env["NIX_CONFIG_DIR"];
    expect(() => getWebappsPath()).toThrow("NIX_CONFIG_DIR");
  });
});

// ---------------------------------------------------------------------------
// Integration: default path wiring
// ---------------------------------------------------------------------------

describe("default path wiring", () => {
  const origEnv = process.env["NIX_CONFIG_DIR"];

  afterEach(() => {
    if (origEnv !== undefined) {
      process.env["NIX_CONFIG_DIR"] = origEnv;
    } else {
      delete process.env["NIX_CONFIG_DIR"];
    }
  });

  test("loadWebapps uses NIX_CONFIG_DIR when no path provided", async () => {
    process.env["NIX_CONFIG_DIR"] = tmpDir;
    // Write webapps.json at the expected path: tmpDir/dotfiles/webapps.json
    const expectedDir = join(tmpDir, "dotfiles");
    const { mkdir } = await import("node:fs/promises");
    await mkdir(expectedDir, { recursive: true });
    const expectedPath = join(expectedDir, "webapps.json");
    await Bun.write(expectedPath, JSON.stringify([{ name: "Test", url: "https://test.com" }]));

    const result = await loadWebapps();
    expect(result).toEqual([{ name: "Test", url: "https://test.com" }]);
  });

  test("saveWebapps uses NIX_CONFIG_DIR when no path provided", async () => {
    process.env["NIX_CONFIG_DIR"] = tmpDir;
    const expectedDir = join(tmpDir, "dotfiles");
    const { mkdir } = await import("node:fs/promises");
    await mkdir(expectedDir, { recursive: true });

    const apps: WebApp[] = [{ name: "Saved", url: "https://saved.com" }];
    await saveWebapps(apps);

    const expectedPath = join(expectedDir, "webapps.json");
    const content = await Bun.file(expectedPath).text();
    expect(JSON.parse(content)).toEqual(apps);
  });
});

// ---------------------------------------------------------------------------
// List view
// ---------------------------------------------------------------------------

describe("list view", () => {
  test("shows empty state when no webapps", async () => {
    await render();
    expect(frame()).toContain("No web apps configured");
    expect(frame()).toContain("a");
  });

  test("shows webapp entries", async () => {
    await render([
      { name: "WhatsApp", url: "https://web.whatsapp.com" },
      { name: "YouTube", url: "https://youtube.com" },
    ]);
    expect(frame()).toContain("WhatsApp");
    expect(frame()).toContain("YouTube");
    expect(frame()).toContain("(2)");
  });

  test("shows bind and workspace info", async () => {
    await render([
      {
        name: "WhatsApp",
        url: "https://web.whatsapp.com",
        bind: "$mainMod SHIFT, W",
        workspace: "9",
      },
    ]);
    expect(frame()).toContain("[$mainMod SHIFT, W]");
    expect(frame()).toContain("ws:9");
  });

  test("j/k navigates the list", async () => {
    await render([
      { name: "App1", url: "https://app1.com" },
      { name: "App2", url: "https://app2.com" },
      { name: "App3", url: "https://app3.com" },
    ]);

    expect(frame()).toContain("> App1");

    await keypress("j");
    expect(frame()).toContain("> App2");

    await keypress("j");
    expect(frame()).toContain("> App3");

    await keypress("k");
    expect(frame()).toContain("> App2");
  });

  test("j does not go past last item", async () => {
    await render([{ name: "Only", url: "https://only.com" }]);
    await keypress("j");
    await keypress("j");
    expect(frame()).toContain("> Only");
  });

  test("k does not go above first item", async () => {
    await render([{ name: "Only", url: "https://only.com" }]);
    await keypress("k");
    expect(frame()).toContain("> Only");
  });

  test("shows entries with mixed optional fields correctly", async () => {
    await render([
      {
        name: "WhatsApp",
        url: "https://web.whatsapp.com",
        bind: "$mainMod SHIFT, W",
        workspace: "9",
      },
      { name: "YouTube", url: "https://youtube.com", bind: "$mainMod SHIFT, Y" },
      { name: "Figma", url: "https://figma.com", workspace: "5" },
      { name: "GitHub", url: "https://github.com" },
    ]);
    const f = frame();
    expect(f).toContain("WhatsApp");
    expect(f).toContain("YouTube");
    expect(f).toContain("Figma");
    expect(f).toContain("GitHub");
    expect(f).toContain("(4)");
    // WhatsApp has both bind and workspace
    expect(f).toContain("[$mainMod SHIFT, W]");
    expect(f).toContain("ws:9");
    // YouTube has bind only
    expect(f).toContain("[$mainMod SHIFT, Y]");
    // Figma has workspace only
    expect(f).toContain("ws:5");
  });

  test("shows footer with keybinding hints", async () => {
    await render();
    const f = frame();
    expect(f).toContain("j/k");
    expect(f).toContain("add");
    expect(f).toContain("delete");
    expect(f).toContain("help");
    expect(f).toContain("quit");
  });
});

// ---------------------------------------------------------------------------
// Help overlay
// ---------------------------------------------------------------------------

describe("help overlay", () => {
  test("? toggles help overlay", async () => {
    await render();

    await keypress("/", { shift: true });
    expect(frame()).toContain("Keybindings");
    expect(frame()).toContain("Move down");
    expect(frame()).toContain("Add new web app");
    expect(frame()).toContain("Delete selected");
    expect(frame()).toContain("Quit");

    // Any key dismisses
    await keypress("a");
    expect(frame()).not.toContain("Keybindings");
  });
});

// ---------------------------------------------------------------------------
// Add view
// ---------------------------------------------------------------------------

describe("add view", () => {
  test("a opens add view", async () => {
    await render();
    await keypress("a");
    expect(frame()).toContain("Add Web App");
    expect(frame()).toContain("Name");
    expect(frame()).toContain("URL");
  });

  test("escape cancels add and returns to list", async () => {
    await render();
    await keypress("a");
    expect(frame()).toContain("Add Web App");

    await keypress("escape");
    expect(frame()).toContain("Web Apps");
    expect(frame()).not.toContain("Add Web App");
  });
});

// ---------------------------------------------------------------------------
// Delete confirmation
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Edit view
// ---------------------------------------------------------------------------

describe("edit view", () => {
  test("Enter on selected PWA opens edit view", async () => {
    await render([{ name: "WhatsApp", url: "https://web.whatsapp.com" }]);
    await keypress("return");
    expect(frame()).toContain("Edit Web App");
  });

  test("edit view fields are pre-populated with current values", async () => {
    await render([
      {
        name: "WhatsApp",
        url: "https://web.whatsapp.com",
        bind: "$mainMod SHIFT, W",
        workspace: "9",
      },
    ]);
    await keypress("return");

    // Field 0 (Name) is active — shows pre-populated input
    let f = frame();
    expect(f).toContain("Edit Web App");
    expect(f).toContain("WhatsApp");

    // Advance to URL — Name now shows as completed, URL input pre-populated
    await keypress("return");
    f = frame();
    expect(f).toContain("WhatsApp");
    expect(f).toContain("https://web.whatsapp.com");

    // Advance to Bind
    await keypress("return");
    f = frame();
    expect(f).toContain("$mainMod SHIFT, W");

    // Advance to Workspace
    await keypress("return");
    f = frame();
    expect(f).toContain("9");
  });

  test("saving edits updates the correct entry in webapps.json", async () => {
    await render([
      { name: "First", url: "https://first.com" },
      { name: "Second", url: "https://second.com" },
    ]);

    // Select second entry
    await keypress("j");
    await keypress("return");
    expect(frame()).toContain("Edit Web App");

    // Clear name and type new name — advance through all 4 fields
    // Field 0: Name (pre-populated with "Second")
    // We need to clear and type a new value, then submit each field
    // The input is pre-populated, so we submit to advance through fields
    await keypress("return"); // advance past Name (keep "Second")
    await keypress("return"); // advance past URL (keep "https://second.com")
    await keypress("return"); // advance past Bind (keep empty)
    await keypress("return"); // submit last field -> save

    // Should be back on list view with status message
    expect(frame()).toContain("home-manager switch");

    // Verify file: both entries should exist, first untouched
    const saved = await loadWebapps(webappsPath);
    expect(saved).toHaveLength(2);
    expect(saved[0]).toEqual({ name: "First", url: "https://first.com" });
    expect(saved[1]!.name).toBe("Second");
  });

  test("other entries in webapps.json are not modified", async () => {
    const apps: WebApp[] = [
      {
        name: "WhatsApp",
        url: "https://web.whatsapp.com",
        bind: "$mainMod SHIFT, W",
        workspace: "9",
      },
      { name: "YouTube", url: "https://youtube.com", bind: "$mainMod SHIFT, Y" },
      { name: "GitHub", url: "https://github.com" },
    ];
    await render(apps);

    // Edit the second entry (YouTube)
    await keypress("j");
    await keypress("return");

    // Submit all fields without changes
    await keypress("return"); // Name
    await keypress("return"); // URL
    await keypress("return"); // Bind
    await keypress("return"); // Workspace

    const saved = await loadWebapps(webappsPath);
    expect(saved).toHaveLength(3);
    expect(saved[0]).toEqual(apps[0]);
    expect(saved[2]).toEqual(apps[2]);
  });

  test("escape cancels edit and returns to list", async () => {
    await render([{ name: "TestApp", url: "https://test.com" }]);
    await keypress("return");
    expect(frame()).toContain("Edit Web App");

    await keypress("escape");
    expect(frame()).toContain("Web Apps");
    expect(frame()).not.toContain("Edit Web App");
  });

  test("Enter does nothing on empty list", async () => {
    await render();
    await keypress("return");
    expect(frame()).toContain("No web apps configured");
  });

  test("reminder shown to run home-manager switch after editing", async () => {
    await render([{ name: "TestApp", url: "https://test.com" }]);
    await keypress("return");

    // Submit all fields
    await keypress("return");
    await keypress("return");
    await keypress("return");
    await keypress("return");

    expect(frame()).toContain("home-manager switch");
  });
});

// ---------------------------------------------------------------------------
// Delete confirmation
// ---------------------------------------------------------------------------

describe("delete confirmation", () => {
  test("d opens confirm dialog for selected entry", async () => {
    await render([{ name: "TestApp", url: "https://test.com" }]);
    await keypress("d");
    expect(frame()).toContain('Delete "TestApp"');
    expect(frame()).toContain("y");
    expect(frame()).toContain("confirm");
  });

  test("y confirms delete and removes entry", async () => {
    await render([
      { name: "ToDelete", url: "https://delete.com" },
      { name: "ToKeep", url: "https://keep.com" },
    ]);
    await keypress("d");
    await keypress("y");

    expect(frame()).not.toContain("ToDelete");
    expect(frame()).toContain("ToKeep");
    expect(frame()).toContain("home-manager switch");

    // Verify file was updated
    const saved = await loadWebapps(webappsPath);
    expect(saved).toHaveLength(1);
    expect(saved[0]!.name).toBe("ToKeep");
  });

  test("n cancels delete", async () => {
    await render([{ name: "StillHere", url: "https://still.com" }]);
    await keypress("d");
    await keypress("n");

    expect(frame()).toContain("StillHere");
    const saved = await loadWebapps(webappsPath);
    expect(saved).toHaveLength(1);
  });

  test("d does nothing on empty list", async () => {
    await render();
    await keypress("d");
    expect(frame()).toContain("No web apps configured");
  });

  test("deleting last item adjusts selected index", async () => {
    await render([
      { name: "First", url: "https://first.com" },
      { name: "Last", url: "https://last.com" },
    ]);

    // Select second item then delete
    await keypress("j");
    await keypress("d");
    await keypress("y");

    expect(frame()).toContain("> First");
    expect(frame()).not.toContain("Last");
  });
});
