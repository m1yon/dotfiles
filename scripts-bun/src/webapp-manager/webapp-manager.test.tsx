import { describe, test, expect, afterEach, beforeEach } from "bun:test";
import { testRender } from "@opentui/react/test-utils";
import { act } from "react";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { mkdtemp, rm } from "node:fs/promises";
import { App } from "./app.tsx";
import { loadWebapps, saveWebapps, type WebApp } from "./webapps.ts";

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
