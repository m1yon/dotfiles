export function renderPrompt(
  template: string,
  vars: Record<string, string>,
): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_: string, key: string) => vars[key] ?? "");
}
