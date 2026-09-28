# HELL ASCENT - Release Notes 2026-09-30

## Layer One: ASHEN VERGE

First release candidate.

### Core loop

- Break three Soul Seals.
- Escape through the Black Gate within 10 minutes.
- Death costs 20 seconds.
- Soul Anchors update the respawn point and restore HP / stamina.

### THE WARDEN

- Appears after the first seal.
- Stage 1: direct observation can stop it.
- Stage 2: observation only slows it.
- Stage 3: observation no longer works.
- Threat feedback increases as it gets closer.

### Movement

- Stamina sprint for keyboard, touch and gamepad.
- Server-authoritative sprint state.
- No idle stamina drain.
- Stamina restored at Soul Anchors and after death.

### Risk / route choice

- ASH RIFT unlocks after two seals.
- Costs 25 HP.
- Usable once per run.
- Provides a shortcut toward the final seal.

### Final Run

- Third seal opens the Black Gate.
- Final Run restores a minimum stamina reserve.
- Dedicated HUD shows distance to the Black Gate and THE WARDEN.

### Replay

- Clear time.
- Death count.
- Session personal best.
- Immediate RETRY.

### Release safety

- First-run tutorial explains the objective, sprint and death penalty.
- Per-seal replicated state can rebuild client progression UI.
- Server periodically repairs progression attributes from authoritative run state.
- Players who fall below the world through an unintended void are returned to the latest Soul Anchor.
- Studio Output logs clear time, deaths, ASH RIFT usage and self-repair events.

### Release stability

- Streaming disabled for the small Layer One map.
- Release sanity check verifies required runtime-generated world objects.
- Release snapshot branch: `release-2026-09-30`.
