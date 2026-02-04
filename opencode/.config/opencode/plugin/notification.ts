import type { Plugin } from "@opencode-ai/plugin";

type Client = Parameters<Plugin>[0]["client"];

export const NotifyPlugin: Plugin = async ({ client, $ }) => {
  return {
    async event(input) {
      // @ts-ignore
      if (input.event.type === "question.asked") {
        // @ts-expect-error does not recognize question.asked type yet
        const sessionID = input.event.properties.sessionID;

        const messageText = await getLatestMessageText(
          client,
          sessionID,
          "A question was asked.",
        );
        await $`notify-send "OpenCode" "${messageText}" --icon=dialog-information`;
      }

      if (input.event.type === "session.idle") {
        const sessionID = input.event.properties.sessionID;

        // Check if this is a main session or a subagent (child) session
        try {
          const sessionResult = await client.session.get({
            path: { id: sessionID },
          });

          // If it has a parentID, it's a subagent. Skip notification.
          if (sessionResult.data && sessionResult.data.parentID) {
            return;
          }
        } catch (e) {
          // Continue with notification even if session check fails
        }

        const messageText = await getLatestMessageText(
          client,
          sessionID,
          "Task Completed",
        );

        await $`notify-send "OpenCode" "${messageText}" --icon=dialog-information`;
      }
    },
  };
};

async function getLatestMessageText(
  client: Client,
  sessionID: string,
  fallback: string,
): Promise<string> {
  try {
    const response = await client.session.messages({
      path: { id: sessionID },
    });

    if (response.data && response.data.length > 0) {
      // Get the last message
      const lastMessage = response.data[response.data.length - 1];

      // Only use assistant messages
      if (lastMessage?.info.role === "assistant") {
        // Find the last text part
        // We cast to any because the type definition might be strict about the union
        const parts = lastMessage.parts as any[];
        const textParts = parts.filter((p) => p.type === "text");

        if (textParts.length > 0) {
          const lastText = textParts[textParts.length - 1].text;

          // Clean up the text: remove code blocks, newlines, extra spaces
          const cleanText: string = lastText
            .replace(/```[\s\S]*?```/g, "") // Remove code blocks
            .replace(/`[^`]*`/g, "") // Remove inline code
            .replace(/\n/g, " ") // Replace newlines with spaces
            .replace(/\s+/g, " ") // Collapse spaces
            .trim();

          // Take the first 5 words
          const words = cleanText.split(" ").filter((w) => w.length > 0);
          if (words.length > 0) {
            return (
              words.slice(0, 5).join(" ") + (words.length > 5 ? "..." : "")
            );
          }
        }
      }
    }
  } catch (e) {
    // console.error("Error fetching messages:", e)
  }

  return fallback;
}
