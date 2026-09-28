# HELL ASCENT

Dark-fantasy Roblox escape game.

## Release candidate

**Layer One: ASHEN VERGE** is feature-frozen for the 2026-09-30 playtest/release candidate.

The current goal is simple:

1. Break all 3 Soul Seals.
2. Survive THE WARDEN.
3. Reach the Black Gate before Soul Decay reaches zero.

## Current gameplay

- 10-minute Layer One run
- 3 Soul Seals
- Soul Anchor checkpoints with HP and stamina recovery
- 20-second death penalty
- 6-second safety window after respawn
- THE WARDEN with three escalating pursuit stages
- Stage 1: looking at the Warden can stop it
- Stage 2: looking at it only slows it
- Stage 3: gaze no longer works
- Hell Escalation atmosphere as seals break
- FINAL RUN after the third seal
- Stamina sprint
- Optional ASH RIFT shortcut after 2 seals, costing 25 HP
- Session personal-best clear time
- Retry flow after escape
- Mobile-friendly objective markers and navigation
- Release sanity check in Studio Output

## Controls

### PC

- Move: standard Roblox controls
- Sprint: hold **Shift**
- Interact: **E** / ProximityPrompt

### Mobile

- Move: standard Roblox touch controls
- Sprint: hold the **走る** button
- Interact: tap the ProximityPrompt

### Gamepad

- Sprint: **L3**

## Tomorrow's shortest launch path

From PowerShell:

```powershell
cd "$HOME\Documents\hell-ascent"
git pull
rojo serve
```

Then in Roblox Studio:

1. Stop any running Play session.
2. Connect the Rojo plugin.
3. Accept the sync.
4. Press Play.
5. Confirm Studio Output contains:
   `[HELL ASCENT] RELEASE READY - required Layer One systems generated`
6. Complete one full run.
7. If the run reaches the Black Gate and RETRY works, publish to Roblox.

See `docs/RELEASE_2026-09-30.md` for the final smoke test.

## Project structure

```text
hell-ascent/
├─ default.project.json
├─ docs/
└─ src/
   ├─ server/
   │  ├─ HellAscent.server.lua
   │  └─ WardenPolish.server.lua
   ├─ client/
   │  └─ HellAscent.client.lua
   └─ shared/
      └─ GameConfig.lua
```

## Optional local assets

The runtime-generated world is playable without Creator Store assets.

If `ServerStorage/HellAscentAssets` contains the optional templates below, the server can use them as decoration:

- HellTree
- HellSkull
- HellChain
- HellTombstone

Third-party scripts are stripped from supported decoration templates before they are used.
