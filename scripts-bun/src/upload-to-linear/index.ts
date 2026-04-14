#! /usr/bin/env bun
// ---
// description: Upload a local file to Linear's asset storage and print the hosted URL
// ---
import { LinearClient } from "@linear/sdk";
import { basename } from "node:path";
import { stat, readFile } from "node:fs/promises";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

function getLinearClient(): LinearClient {
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    console.error("ERROR: LINEAR_API_KEY environment variable is required");
    process.exit(1);
  }
  return new LinearClient({ apiKey });
}

function guessContentType(path: string): string {
  const ext = path.toLowerCase().split(".").pop();
  switch (ext) {
    case "png":
      return "image/png";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "gif":
      return "image/gif";
    case "webp":
      return "image/webp";
    case "svg":
      return "image/svg+xml";
    case "mp4":
      return "video/mp4";
    case "webm":
      return "video/webm";
    case "pdf":
      return "application/pdf";
    default:
      return "application/octet-stream";
  }
}

async function uploadFile(path: string, contentType?: string): Promise<string> {
  const client = getLinearClient();
  const { size } = await stat(path);
  const name = basename(path);
  const type = contentType ?? guessContentType(path);

  const payload = await client.fileUpload(type, name, size);
  if (!payload.success || !payload.uploadFile) {
    throw new Error("Linear rejected fileUpload request");
  }

  const { uploadUrl, assetUrl, headers: extraHeaders } = payload.uploadFile;

  const headers = new Headers();
  headers.set("Content-Type", type);
  headers.set("Cache-Control", "public, max-age=31536000");
  for (const { key, value } of extraHeaders) {
    headers.set(key, value);
  }

  const body = await readFile(path);
  const res = await fetch(uploadUrl, { method: "PUT", headers, body });
  if (!res.ok) {
    throw new Error(
      `PUT to Linear asset storage failed: ${res.status} ${res.statusText}`,
    );
  }

  return assetUrl;
}

yargs(hideBin(process.argv))
  .scriptName("upload-to-linear")
  .usage(
    "$0 <path> [--content-type <mime>]\n\nUploads a local file to Linear's asset storage and prints the hosted URL to stdout.\nEmbed the printed URL in markdown as ![alt](URL) in an issue/comment/document body.",
  )
  .command(
    "$0 <path>",
    "Upload a file",
    (y) =>
      y
        .positional("path", {
          type: "string",
          description: "Path to the local file to upload",
          demandOption: true,
        })
        .option("content-type", {
          type: "string",
          description: "MIME type override (inferred from extension by default)",
        }),
    async (argv) => {
      const url = await uploadFile(
        argv.path as string,
        argv["content-type"] as string | undefined,
      );
      console.log(url);
    },
  )
  .demandCommand(1)
  .strict()
  .help()
  .parseAsync()
  .catch((err) => {
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  });
