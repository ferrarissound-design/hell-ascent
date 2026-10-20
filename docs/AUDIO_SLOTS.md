# HELL ASCENT - Audio slots

The game is fully wired for sound but ships **silent**: every slot in `Config.Audio`
(`src/shared/GameConfig.lua`) is an empty string, and an empty string means "do nothing".
Nothing breaks if you leave them empty.

Fill a slot with an asset id you own or are allowed to use in your experience:

```lua
Config.Audio.Ambience = "rbxassetid://123456789"
```

Roblox restricts which audio can be used in a published experience, so upload your own
(Creator Hub -> Audio) or pick audio your experience has access to. Test it in Studio before publishing.

| Slot | Plays when | Loop | Notes |
| --- | --- | --- | --- |
| `Ambience` | Run starts / client loads | yes | Low drone or wind. Stops on expiry and escape. |
| `Heartbeat` | Warden is near | yes | Volume 0.15-1.0 and speed 0.85-1.75x scale with proximity; stops when far. Use a clean single-beat loop. |
| `SealBreak` | Soul Seal broken | no | Short, heavy. Pairs with a camera shake. |
| `EmberPickup` | Soul Ember collected | no | Bright, short. Fires often; keep it under ~1s. |
| `Checkpoint` | Soul Anchor reached | no | Warm "safe" cue. |
| `WardenAwake` | First seal broken | no | The Warden stirring. |
| `WardenStrike` | Warden hits the player | no | Impact. Pairs with shake and rumble. |
| `VentWarn` | Ember Vent starts flickering | no | Positional (3D) at each vent, up to 140 studs. |
| `VentBlast` | Ember Vent erupts | no | Positional (3D) at each vent. |
| `AshRift` | ASH RIFT used | no | Teleport whoosh. |
| `GateOpen` | Third seal broken | no | Gate opening. |
| `DeathToll` | Player dies | no | Pairs with the 20s/30s penalty toast. |
| `Escape` | Player escapes | no | Ending sting. |

Client-only slots are played from `src/client/HellAscent.client.lua`; `VentWarn` and `VentBlast`
are server-played in `src/server/WorldExtras.lua` so everyone nearby hears them.
Per-slot volume lives in `soundVolumes` at the top of the audio block in the client script.
