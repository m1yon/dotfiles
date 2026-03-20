type Urgency = "low" | "normal" | "critical";

export async function notify(
  title: string,
  body: string,
  urgency: Urgency = "normal",
): Promise<void> {
  const proc = Bun.spawn(
    ["notify-send", `--urgency=${urgency}`, title, body],
    { stdout: "ignore", stderr: "ignore" },
  );
  await proc.exited;
}
