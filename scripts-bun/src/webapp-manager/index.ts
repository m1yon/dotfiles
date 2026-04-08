#!/usr/bin/env bun
// ---
// description: Manage Progressive Web App entries in webapps.json
// ---

import { createCliRenderer } from "@opentui/core";
import { createRoot } from "@opentui/react";
import { createElement } from "react";
import { App } from "./app.tsx";

const renderer = await createCliRenderer({
  exitOnCtrlC: true,
});

createRoot(renderer).render(createElement(App));
