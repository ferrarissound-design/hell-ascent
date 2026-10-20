# HELL ASCENT

Dark-fantasy Roblox escape game.

## Status

**Layer One: ASHEN VERGE — v1.0.0.** The original 2026-09-30 release candidate was feature-frozen; v1.0.0 adds the
replay and polish layer on top of it (Soul Embers, Ember Vents, NIGHTMARE, grades, saved records, audio hooks).
See `docs/RELEASE_NOTES_1.0.0.md`.

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

### Added in v1.0.0

- **Soul Embers** — 10 optional pale-blue pickups off the main route. Each one gives back run time (+8s NORMAL / +6s NIGHTMARE).
- **Ember Vents** — 10 fire vents on Bone Field, Execution Causeway and Gate Plaza. Glow flickers, then blasts: 28 damage once per eruption.
- **NIGHTMARE** — unlocks after your first escape. 8-minute timer, 30s death penalty, faster and harder-hitting Warden, Soul Anchors only heal half.
- **Grades S / A / B / C** — based on effective clear time and deaths (thresholds in `Config.Ranks`).
- **Saved progress** — escapes, best times and the NIGHTMARE unlock persist through DataStore, and show on the player list (`Escapes`, `Best`).
- **Seal whispers** — each Soul Seal reveals a line of lore when broken.
- **Feel** — camera shake, gamepad rumble and a heartbeat that follows the Warden's proximity.
- **Audio slots** — all sounds are wired up but ship empty. Fill `Config.Audio` (see `docs/AUDIO_SLOTS.md`).

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

Release support files:

- `docs/ROBLOX_PUBLISHING.md` - title, descriptions, controls and recommended first-release settings
- `docs/SCREENSHOT_PLAN.md` - three screenshots to capture during the final run
- `docs/RELEASE_NOTES_2026-09-30.md` - first-release feature summary
- `docs/RELEASE_NOTES_1.0.0.md` - v1.0.0 additions, known limits and tuning notes
- `docs/AUDIO_SLOTS.md` - every sound slot, what triggers it, and how to fill it

## Project structure

```text
hell-ascent/
├─ default.project.json
├─ docs/
└─ src/
   ├─ server/
   │  ├─ HellAscent.server.lua
   │  ├─ WardenPolish.server.lua
   │  ├─ WorldExtras.lua      (Soul Embers, Ember Vents)
   │  └─ Persistence.lua      (DataStore load/save with merge)
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

## Saved progress (DataStore)

Records are stored under the `HellAscent_Profile_v1` DataStore, keyed by UserId. Saving merges instead of overwriting,
so an old server can never erase a better time or the NIGHTMARE unlock.

- In Studio, enable **Game Settings → Security → Enable Studio Access to API Services**, and publish the place once.
- If the DataStore is unreachable the game still runs; records are session-only and Output shows a single
  `[HELL ASCENT][DATA]` warning.

## Tuning

Everything balance-related is in `src/shared/GameConfig.lua`: `Difficulties`, `Ranks`, `SoulEmbers`, `Vents`, `Warden`, `Sprint`.
Change one value at a time after a full run.
