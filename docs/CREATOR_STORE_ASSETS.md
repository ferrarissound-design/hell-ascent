# Toolbox asset workflow

HELL ASCENT no longer loads third-party Creator Store assets at runtime.

Instead, insert the chosen models into Roblox Studio once and keep them as local templates inside the place.

## Required Studio structure

Create this folder manually:

```text
ServerStorage
└─ HellAscentAssets
   ├─ HellTree
   ├─ HellSkull
   ├─ HellChain
   └─ HellTombstone
```

The models can come from Creator Store / Toolbox.

## Important

Rename the inserted models exactly:

- `HellTree`
- `HellSkull`
- `HellChain`
- `HellTombstone`

The server script will:

- find the templates
- clone them
- remove scripts, prompts, click detectors, and touch transmitters from clones
- anchor all parts
- resize them
- place them around Layer One automatically

If one template is missing, only that decoration type is skipped. The generated game world remains playable.

## Why this workflow

This avoids runtime third-party asset permission issues and makes the visual assets part of the place itself rather than a live external dependency.
