import { icon } from "./icons";

export function logQueryMessage(message: any): void {
  if (message.type !== "assistant") return;
  const isSubagent = !!message.parent_tool_use_id;
  const content = message.message?.content ?? [];
  for (const block of content) {
    if (block.type === "text") {
      if (isSubagent) {
        console.log(
          `\x1b[90m  \u2503 \x1b[34m[sub]\x1b[90m ${block.text}\x1b[0m`,
        );
      } else {
        console.log(`\x1b[38;2;227;137;58m[${icon.claude} Claude]\x1b[0m ${block.text}`);
      }
    } else if (block.type === "tool_use") {
      if (isSubagent) {
        console.log(
          `\x1b[90m  \u2503 [${block.name}] ${JSON.stringify(block.input).slice(0, 200)}\x1b[0m`,
        );
      } else if (block.name === "Agent") {
        const agentType = block.input?.subagent_type ?? "General";
        console.log(
          `\x1b[34m[Subagent(${agentType})]\x1b[0m \x1b[37m${block.input?.description ?? ""}\x1b[0m`,
        );
      } else if (block.name === "Skill") {
        console.log(
          `\x1b[35m[${icon.skill} Skill(${block.input?.skill ?? "unknown"})]\x1b[0m \x1b[37mSkill loaded\x1b[0m`,
        );
      } else {
        console.log(
          `\x1b[36m[${block.name}]\x1b[0m \x1b[90m${JSON.stringify(block.input).slice(0, 200)}\x1b[0m`,
        );
      }
    }
  }
}
