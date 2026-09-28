# Creator Store assets

Layer One uses optional Creator Store MeshParts as a decoration pass.

| Purpose | Asset | ID |
| --- | --- | ---: |
| Dead trees | Dead Tree by @SheriffTaco | 591112009 |
| Skulls | skull by @angrybird0627 | 10834008239 |
| Chains | Chain by @DevRedIte | 9772738118 |
| Tombstones | Tombstone by @brightdani | 491290309 |

## Safety / fallback

The game does not import third-party scripts.

Only MeshPart content is requested. Every load is wrapped in `pcall`; if Roblox refuses an asset because of permissions, moderation, availability, or API behavior, the generated primitive scenery remains and gameplay continues.

The asset IDs live in:

`src/shared/AssetConfig.lua`

The placement pass lives in:

`src/server/HellAscent.server.lua`
