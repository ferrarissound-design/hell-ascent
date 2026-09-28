# HELL ASCENT

A Roblox dark-fantasy escape game.

## Layer One: Ashen Verge

The first prototype is already playable through Rojo and is generated from Luau at runtime.

### Current route

1. **Ash Shore** - the soul wakes in Layer One.
2. **Ash Bridge** - broken slabs over the burning abyss.
3. **Bone Field** - dead trees, pale markers and the first deeper checkpoint.
4. **Execution Causeway** - a narrow approach toward the final structure.
5. **The Black Gate** - crossing the veil clears Layer One.

### Implemented

- Rojo project structure
- Runtime-generated Layer One map
- Hell lighting, fog, atmosphere and color grading
- Lava / death hazard
- Respawn checkpoints ("Soul Anchors")
- Mobile-friendly HUD
- Intro presentation
- Giant Black Gate landmark
- Layer One clear sequence
- Structure prepared for later Creator Store asset replacement

## Run with Rojo

From the repository folder:

```powershell
rojo serve
```

Then open Roblox Studio, connect with the Rojo plugin, and start a play test.

## Project structure

```text
hell-ascent/
├─ default.project.json
└─ src/
   ├─ server/
   │  └─ HellAscent.server.lua
   ├─ client/
   │  └─ HellAscent.client.lua
   └─ shared/
      └─ GameConfig.lua
```

## Asset direction

The generated geometry is the prototype skeleton, not the final art.

Next passes can replace or enrich it with selected Creator Store assets such as:

- ruined structures
- graves and bone piles
- chains and torture props
- dead trees
- demon / guardian statues
- rock formations
- gate ornament
- ambient audio

Third-party scripts should not be trusted by default. Visual assets should be inspected and unnecessary scripts removed before use.
