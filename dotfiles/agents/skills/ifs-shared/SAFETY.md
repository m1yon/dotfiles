# SAFETY.md — refusal criteria, crisis patterns, dissociation cue, tier matrix

Hard guardrails for `/em-ifs-session`. EM+IFS assumes stable Self gives the user enough access to notice; safety is mostly passive. The active checks are: pre-flight scaffolding, mood-step refusal, mid-session imminent-harm pattern match, dissociation cue at locate-in-body.

## Pre-flight refusals (run before check-in)

### Refusal 1 — IFS.md scaffolding

If `<vault>/6 - Full Notes/IFS/IFS.md` is missing, OR exists but lacks `crisis_fallback:` in frontmatter:

> Can't run — `6 - Full Notes/IFS/IFS.md` is missing or has no `crisis_fallback:` pointer. See `dotfiles/agents/skills/em-ifs-session/README.md` for setup; copy from `templates/IFS.md`.

### Refusal 2 — Crisis Plan

Resolve the wikilink target of `crisis_fallback:` (e.g. `[[Crisis Plan]]` → `<vault>/6 - Full Notes/IFS/Crisis Plan.md`). If missing:

> Can't run — `crisis_fallback:` points to `[[<target>]]` but that page doesn't exist. See `dotfiles/agents/skills/em-ifs-session/README.md` for setup; copy from `templates/Crisis Plan.md` and author it in a non-crisis moment.

No therapist-voice boilerplate. One line, name what's missing.

## Mood-step refusal criteria (run on check-in step 1 only)

Refuse if the mood input matches any of:

- **Active suicidal ideation** — explicit plan, means, or timeline. Not vague distress.
- **Acute crisis within last 24h** — assault, recent loss, medical emergency, ongoing violence.
- **Intoxication** — explicit mention of being high / drunk / on substances right now.

On match: emit the crisis fallback link in one line and close. Never ask tier.

> Going to the crisis plan. [[Crisis Plan]].

Pattern guidance (not exhaustive, use judgment):

- SI: "going to kill myself", "have a plan", "tonight is it", "method/means" mentions, "everyone would be better off without me" + concreteness.
- Acute crisis: "just been assaulted", "she just left", "just got the diagnosis", "ER right now", "in the middle of [event]".
- Intoxication: "drunk", "high", "took [substance]", "few drinks in", "tripping".

**Does NOT refuse on high distress alone.** High distress is exactly when EM+IFS helps. "I'm overwhelmed", "I'm panicking", "I can't stop crying", "I feel hopeless" — these proceed to tier. The gate is plan/means/24h-acute/substances.

## Imminent-harm pattern match (mid-session, the only break in propose-and-ratify)

If user text mid-session looks like an acute emergency signal (explicit imminent-harm statement), break protocol immediately with:

> Going to the crisis plan. [[Crisis Plan]].

No pulse-check, no closing ritual, session ends. Subagent dispatched with `status: crisis_exit`.

## Dissociation cue (Phase 3 step 1, locate-in-body)

At locate-in-body, ask:

> Check: can you still feel the chair / your feet / the room?

A bail at that cue is treated as a hard "close now, no deeper contact" — route to closing ritual; do not enter Phase 3 step 2.

## Pulse cadence (mid-session, hybrid)

- **Light pulse at every phase transition.** *"Still here and oriented? Want to continue?"* Yes → continue. Anything else → branch to closing ritual.
- **Full continuation check** at three high-risk transitions: entering Phase 3, entering Phase 7, pre-close. Full check = light pulse + texture pulse + Self-like-parts spotting (per `PROTOCOL.md` §5a).
- Otherwise passive — over-scanning is fragile and infantilizing.

## Tier matrix (depth gating)

| Tier   | Range       | Phase 7 (exile contact / unburdening) |
| ------ | ----------- | -------------------------------------- |
| Short  | ~15–25 min  | Blocked entirely                       |
| Medium | ~30–45 min  | Only with explicit user request + protector permission + clean Self texture + no Self-like-part in latest continuation check |
| Long   | ~60–90 min  | Per protocol (protector permission + clean texture + no current Self-like-part required) |

**Two-factor gate for Phase 7.** All four must hold:

1. Tier permits (medium with explicit request, or long).
2. Protector permission.
3. Phase 1 produced clean Self texture (no Self-like-part detected at the gate).
4. No Self-like-part detected in current continuation check.

Either factor failing blocks Phase 7. Even on a long session with protector permission, murky texture is a stop.

**Self-like-part detected at any gate → Phase 7 blocked for this session regardless of tier.** This is a hard rule, not a tier-dependent one.

## Bail handling

Any bail (other than imminent-harm exit) runs the closing ritual. Session logged as `status: interrupted`. Every part touched gets `left_without_resolution: true` in its frontmatter. The pending-changes log is applied in full.

## Wrap behavior (tier upper bound)

- **Soft wrap** — ~5 min before upper bound. AI proposes once: *"We're near your time — want to close, or keep going?"* User ratifies close → skip unworked phases, route to closing ritual. Keep going → AI does not re-propose for ~10 min.
- **Firm wrap** — at upper bound. AI proposes again, firmer.
- **Wrap never cuts mid-phase.** If wrap is ratified mid-engagement, finish that phase's contact, then closing ritual.
- **The closing ritual always runs** unless an imminent-harm exit fired.
- Crisis-pattern override ignores wrap state and closes immediately.
