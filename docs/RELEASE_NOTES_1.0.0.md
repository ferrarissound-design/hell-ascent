# HELL ASCENT - Release Notes 1.0.0

Layer One: ASHEN VERGE. Builds on the 2026-09-30 release candidate; the core loop is unchanged
(3 Soul Seals -> survive THE WARDEN -> Black Gate).

## New

### Soul Embers
10 optional pickups, placed off the shortest route. Each restores run time
(+8s NORMAL, +6s NIGHTMARE). Collection is per player and resets on restart. They are the answer to
"is that detour worth it?", and the reason a perfect run is not simply a straight line.

### Ember Vents
10 rhythm hazards on Bone Field, Execution Causeway and Gate Plaza. Telegraph (flicker ~1.4s) -> blast (~0.9s)
-> idle, every 6s, staggered per vent. 28 damage once per eruption. Respawn protection and the ASH RIFT
arrival window apply. Ash Shore stays hazard-free so the opening is calm.

### NIGHTMARE
Unlocked by the first escape. 8:00 timer, 30s death penalty, Warden 12% faster and 32% harder-hitting,
Soul Anchors heal half HP, ember bonus 6s. Stamina and sprint rules are unchanged.

### Grades
S / A / B / C from effective clear time (elapsed + death penalties - ember bonuses, i.e. the HUD timer)
and deaths. Thresholds are ratios of the run duration so they scale with difficulty (`Config.Ranks`).

### Saved progress
DataStore `HellAscent_Profile_v1`: escapes, best time per difficulty, NIGHTMARE unlock. Writes use
`UpdateAsync` with a better-value-wins merge. Leaderboard shows `Escapes` and `Best`.

### Story and feel
Each Soul Seal whispers a line when broken (the last reveals the Warden is chained too). Camera shake,
gamepad rumble, a proximity heartbeat, and a redesigned ending screen with grade, embers, and difficulty choice.

### Audio hooks
13 sound slots, all empty by default. See `AUDIO_SLOTS.md`.

## Internal
- `WorldExtras.lua` and `Persistence.lua` split out of the main server script.
- `exitCooldowns` moved to a module-level table and cleared on `PlayerRemoving`.
- Per-run settings (duration, penalty, Warden scale) now come from `Config.Difficulties`; `RunDurationSeconds`
  and `DeathPenaltySeconds` remain as NORMAL aliases.
- Studio sanity check now also verifies every ember and vent exists. Build attribute is `Config.Version`.

## Known limits (honest list)
- **Not play-tested in Roblox Studio.** Everything was checked with the Luau compiler and analyzer, plus unit
  tests of the save/merge logic. Run `docs/PLAYTEST_CHECKLIST.md` before publishing.
- **Grade thresholds and NIGHTMARE numbers are estimates** from route length and speeds, not measured. Expect to tune.
- **One shared Warden.** Players have independent timers but share a single Warden; it chases the nearest eligible player.
  Fine for solo and small groups, odd with many players.
- **Gaze mechanic is client-reported.** The server verifies line of sight but not camera direction, so a modified client
  could fake "looking at the Warden". Acceptable for a solo escape game; revisit before adding competitive ranking.
- **No audio ships.** The game is silent until `Config.Audio` is filled.
- Only Layer One exists. The ending teases Layer Two.
