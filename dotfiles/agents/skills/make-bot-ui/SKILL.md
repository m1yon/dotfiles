---
name: make-bot-ui
description: Build a page or dashboard that sends actions to a Codex-backed service, keeps credentials on the server, and can be exposed on an existing tailnet.
metadata:
  upstream: https://github.com/cursor/plugins/tree/fae2c6ed95821bd85f614a73e4842e13229fa5e5/pstack/skills/make-bot-ui
  codex-port: "true"
---

# Make a bot UI

Read [Codex runtime](../setup-pstack/references/codex-runtime.md) before following this workflow.

Build a UI the user clicks and a server that forwards a small JSON action to a verified Codex integration. Keep credentials on the server.

## Establish the backend

Inspect the project for an existing agent service, app-server client, SDK integration, or connector that accepts actions. Read its contract and current official documentation before choosing a protocol. Reuse it when it meets the request. If there is no backend, make the UI and server boundary concrete, then obtain the missing endpoint or choose an implementation with the user. Label an unconnected prototype as such.

Codex scheduling tools create scheduled or heartbeat automations. They do not provide an assumed public webhook or sender-key panel. For a request that only needs scheduling, use `automation_update` instead of building a webhook dashboard. For a custom service, verify its actual authentication, request shape, success response, and deduplication behavior.

## Build and verify

1. Define a small action schema. Treat request bodies as data; route allowed actions through validation.
2. Render clear pending, successful, and failed states in the UI. The browser calls the local service; the service calls the agent backend.
3. Obtain credentials through the project's existing secret manager or an ignored local file chosen by the user. Read from that store at runtime. Keep credentials out of browser code, chat, logs, skill files, and Git.
4. Set a timeout. Retry only when the backend supports idempotency or the action is safe to repeat. Record request IDs and sanitized error details so failures can be investigated.
5. Probe a harmless action end to end and verify the actual agent-side result. An HTTP success code alone does not prove that the requested work ran.

## Optional tailnet access

Use an existing Tailscale node when the user requests tailnet access. Read `tailscale status` and `tailscale ip -4` to verify connectivity. Configure the service's bind address or an existing Tailscale Serve route according to the project's deployment conventions and the user's request. Authenticate action requests before exposing the service.

If a package, service, hostname, or system setting needs changing, follow the repository's declarative setup. Do not install Tailscale with a downloaded installer or change system settings as a side effect of creating a UI. Verify the selected URL from a tailnet client before reporting it as reachable.

Report the UI and server paths, the backend used, the harmless action's result, and any connection or deployment work still needed.
