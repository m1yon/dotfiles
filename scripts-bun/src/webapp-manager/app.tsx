import { useState, useEffect } from "react";
import { useKeyboard, useRenderer } from "@opentui/react";
import type { WebApp } from "./webapps.ts";
import { loadWebapps, saveWebapps } from "./webapps.ts";

type View = "list" | "add" | "confirm-delete";

interface AppProps {
  webappsPath?: string;
  initialWebapps?: WebApp[];
}

export function App({ webappsPath, initialWebapps }: AppProps) {
  const renderer = useRenderer();
  const [view, setView] = useState<View>("list");
  const [webapps, setWebapps] = useState<WebApp[]>(initialWebapps ?? []);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [showHelp, setShowHelp] = useState(false);
  const [statusMessage, setStatusMessage] = useState("");

  // Add form state
  const [addField, setAddField] = useState(0);
  const [addName, setAddName] = useState("");
  const [addUrl, setAddUrl] = useState("");
  const [addBind, setAddBind] = useState("");
  const [addWorkspace, setAddWorkspace] = useState("");

  useEffect(() => {
    if (!initialWebapps) {
      loadWebapps(webappsPath).then(setWebapps);
    }
  }, [webappsPath, initialWebapps]);

  const showStatus = (msg: string) => {
    setStatusMessage(msg);
  };

  const resetAddForm = () => {
    setAddField(0);
    setAddName("");
    setAddUrl("");
    setAddBind("");
    setAddWorkspace("");
  };

  const handleAddComplete = async () => {
    if (!addName.trim() || !addUrl.trim()) return;
    const entry: WebApp = { name: addName.trim(), url: addUrl.trim() };
    if (addBind.trim()) entry.bind = addBind.trim();
    if (addWorkspace.trim()) entry.workspace = addWorkspace.trim();
    const updated = [...webapps, entry];
    await saveWebapps(updated, webappsPath);
    setWebapps(updated);
    resetAddForm();
    setView("list");
    showStatus("Added! Run `home-manager switch` to apply.");
  };

  const handleDelete = async () => {
    const updated = webapps.filter((_: WebApp, i: number) => i !== selectedIndex);
    await saveWebapps(updated, webappsPath);
    setWebapps(updated);
    setSelectedIndex(Math.min(selectedIndex, Math.max(0, updated.length - 1)));
    setView("list");
    showStatus("Deleted! Run `home-manager switch` to apply.");
  };

  useKeyboard((key) => {
    // Help toggle works everywhere
    if (key.name === "?" || (key.shift && key.name === "/")) {
      setShowHelp((h: boolean) => !h);
      return;
    }

    if (showHelp) {
      // Any key dismisses help
      setShowHelp(false);
      return;
    }

    if (view === "list") {
      switch (key.name) {
        case "j":
        case "down":
          setSelectedIndex((i: number) => Math.min(webapps.length - 1, i + 1));
          break;
        case "k":
        case "up":
          setSelectedIndex((i: number) => Math.max(0, i - 1));
          break;
        case "a":
          resetAddForm();
          setView("add");
          setStatusMessage("");
          break;
        case "d":
          if (webapps.length > 0) {
            setView("confirm-delete");
            setStatusMessage("");
          }
          break;
        case "q":
        case "escape":
          renderer.destroy();
          break;
      }
    } else if (view === "add") {
      if (key.name === "escape") {
        resetAddForm();
        setView("list");
        return;
      }
      // Tab / Enter advance fields; input handled by <input> component
    } else if (view === "confirm-delete") {
      if (key.name === "y") {
        handleDelete();
      } else {
        setView("list");
      }
    }
  });

  if (showHelp) {
    return <HelpOverlay />;
  }

  if (view === "add") {
    return (
      <AddView
        field={addField}
        setField={setAddField}
        name={addName}
        setName={setAddName}
        url={addUrl}
        setUrl={setAddUrl}
        bind={addBind}
        setBind={setAddBind}
        workspace={addWorkspace}
        setWorkspace={setAddWorkspace}
        onComplete={handleAddComplete}
        onCancel={() => {
          resetAddForm();
          setView("list");
        }}
      />
    );
  }

  if (view === "confirm-delete") {
    const target = webapps[selectedIndex];
    return (
      <box flexDirection="column" padding={1}>
        <text>
          <span fg="#ff5555">Delete "{target?.name}"?</span>
        </text>
        <text>
          Press <span fg="#50fa7b">y</span> to confirm,{" "}
          <span fg="#ff5555">any other key</span> to cancel
        </text>
      </box>
    );
  }

  // List view
  return (
    <box flexDirection="column" width="100%" height="100%">
      <box padding={1} paddingBottom={0}>
        <text>
          <span fg="#bd93f9">
            <strong>Web Apps</strong>
          </span>{" "}
          <span fg="#6272a4">({webapps.length})</span>
        </text>
      </box>

      {webapps.length === 0 ? (
        <box padding={1}>
          <text>
            <span fg="#6272a4">
              No web apps configured. Press <span fg="#50fa7b">a</span> to add
              one.
            </span>
          </text>
        </box>
      ) : (
        <box flexDirection="column" paddingX={1} paddingTop={1}>
          {webapps.map((app: WebApp, i: number) => (
            <text key={app.name}>
              <span fg={i === selectedIndex ? "#50fa7b" : "#f8f8f2"}>
                {i === selectedIndex ? "> " : "  "}
                {app.name}
              </span>
              <span fg="#6272a4"> {app.url}</span>
              {app.bind ? <span fg="#8be9fd"> [{app.bind}]</span> : null}
              {app.workspace ? (
                <span fg="#ffb86c"> ws:{app.workspace}</span>
              ) : null}
            </text>
          ))}
        </box>
      )}

      <box paddingX={1} paddingTop={1}>
        <text>
          <span fg="#6272a4">
            j/k: navigate | a: add | d: delete | ?: help | q: quit
          </span>
        </text>
      </box>

      {statusMessage ? (
        <box paddingX={1}>
          <text>
            <span fg="#f1fa8c">{statusMessage}</span>
          </text>
        </box>
      ) : null}
    </box>
  );
}

function HelpOverlay() {
  const shortcuts = [
    { key: "j / Down", action: "Move down" },
    { key: "k / Up", action: "Move up" },
    { key: "a", action: "Add new web app" },
    { key: "d", action: "Delete selected" },
    { key: "?", action: "Toggle this help" },
    { key: "q / Esc", action: "Quit" },
  ];

  return (
    <box
      flexDirection="column"
      border
      borderStyle="rounded"
      padding={2}
      title="Keybindings"
      titleAlignment="center"
    >
      {shortcuts.map(({ key, action }) => (
        <box key={key} flexDirection="row">
          <text width={15}>
            <span fg="#8be9fd">{key}</span>
          </text>
          <text>
            <span fg="#f8f8f2">{action}</span>
          </text>
        </box>
      ))}
      <box paddingTop={1}>
        <text>
          <span fg="#6272a4">Press any key to close</span>
        </text>
      </box>
    </box>
  );
}

interface AddViewProps {
  field: number;
  setField: (f: number) => void;
  name: string;
  setName: (v: string) => void;
  url: string;
  setUrl: (v: string) => void;
  bind: string;
  setBind: (v: string) => void;
  workspace: string;
  setWorkspace: (v: string) => void;
  onComplete: () => void;
  onCancel: () => void;
}

const ADD_FIELDS = ["Name", "URL", "Bind (optional)", "Workspace (optional)"];

function AddView({
  field,
  setField,
  name,
  setName,
  url,
  setUrl,
  bind,
  setBind,
  workspace,
  setWorkspace,
  onComplete,
  onCancel,
}: AddViewProps) {
  const values = [name, url, bind, workspace];
  const setters = [setName, setUrl, setBind, setWorkspace];

  const handleSubmit = () => {
    if (field < ADD_FIELDS.length - 1) {
      setField(field + 1);
    } else {
      onComplete();
    }
  };

  return (
    <box flexDirection="column" padding={1}>
      <text>
        <span fg="#bd93f9">
          <strong>Add Web App</strong>
        </span>
        <span fg="#6272a4"> (Esc to cancel)</span>
      </text>

      <box flexDirection="column" paddingTop={1}>
        {ADD_FIELDS.map((label, i) => (
          <box key={label} flexDirection="row" gap={1}>
            <text width={22}>
              <span fg={i === field ? "#50fa7b" : "#6272a4"}>
                {i === field ? "> " : "  "}
                {label}:
              </span>
            </text>
            {i < field ? (
              <text>
                <span fg="#f8f8f2">{values[i] || "(empty)"}</span>
              </text>
            ) : i === field ? (
              <input
                value={values[i]!}
                onChange={setters[i]!}
                placeholder={`Enter ${label.toLowerCase().replace(/ \(optional\)/, "")}...`}
                focused
                width={40}
                onSubmit={handleSubmit}
              />
            ) : null}
          </box>
        ))}
      </box>

      <box paddingTop={1}>
        <text>
          <span fg="#6272a4">Enter: next field | Esc: cancel</span>
        </text>
      </box>
    </box>
  );
}
