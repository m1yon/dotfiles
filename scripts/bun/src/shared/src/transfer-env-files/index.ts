#!/usr/bin/env bun
// ---
// description: Copy missing project .env files from another GitHub workspace
// ---
import { runCli } from "./transfer.ts";

runCli(process.argv).catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
});
