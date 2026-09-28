# HELL ASCENT - Layer One Playtest Checklist

Use this checklist when testing the current main branch in Roblox Studio.

## Start of run

- The player spawns safely on Ash Shore.
- The intro explains the rule in a few seconds: break 3 seals, then escape through Black Gate.
- HUD fits on a phone-sized viewport without covering the center of the screen.
- The timer starts close to 10:00.
- HUD shows 0 / 3 Soul Seals.
- A direction and distance to an unbroken seal is visible.
- Warden does not attack before the first seal is broken.

## Soul Seals

Test all three seals.

- Seal markers are visible before reaching the seal.
- The distance shown decreases while approaching.
- The ProximityPrompt is easy to trigger on keyboard and mobile.
- Hold time feels short enough to use while under pressure.
- After breaking a seal:
  - counter increases once,
  - the local seal visibly dims,
  - its prompt is disabled for that player,
  - its navigation marker disappears.
- Returning to a broken seal does not confuse the player into trying to break it again.

## Warden pacing

### After seal 1

- Warden wakes up but does not instantly appear on top of the player.
- The player still has time to explore and choose the next route.
- Warden can navigate ordinary terrain without constantly getting stuck.

### After seal 2

- Pursuit is clearly more dangerous than stage 1.
- The player can still escape by moving well.
- Warden warning appears when it is close enough to matter.

### After seal 3

- HUD switches the navigation target to BLACK GATE.
- Black Gate receives a visible world marker.
- Warden feels dangerous enough to create a final chase.
- Warden should not feel faster than the player to the point that escape is impossible.

## Warden combat

- One hit is noticeable but not an instant kill.
- Red damage feedback is visible.
- Consecutive hits have enough spacing to allow escape.
- Warden cannot kill the player while the player is still loading into a respawn.
- Warden does not fall permanently into the lava or disappear under the map.

## Death and respawn

- Death removes 20 seconds from the timer.
- Player returns to the latest Soul Anchor.
- HUD and seal count remain correct after respawn.
- A 6-second respawn protection message appears after a death.
- During respawn protection, Warden does not target that player.
- Navigation immediately works after respawn.

## Black Gate

### Before 3 seals

- Touching the gate clearly says more seals are required.
- Player is moved a short distance back from the gate rather than becoming trapped in it.
- Gate remains visually understandable as the final destination.

### After 3 seals

- HUD says to head to BLACK GATE.
- Gate world marker is visible.
- Player can pass the gate and finish the layer.
- Escape ending appears only once.

## Mobile check

Use Studio device emulation or a real phone.

- HUD text remains readable.
- Top HUD does not overlap Roblox core buttons excessively.
- ProximityPrompt can be tapped comfortably.
- Camera view is not blocked by large scenery.
- Direction arrows make sense while rotating the camera.
- Warden warning fits on one line or remains understandable if truncated.

## Visual check

Look specifically for:

- oversized generated scenery,
- floating tombstones or rocks,
- chains crossing the main route,
- dead trees blocking camera movement,
- Soul Seal objects floating above or buried in terrain,
- Warden body parts clipping badly after scaling,
- Black Gate text or marker dominating the whole screen.

## Balance knobs

Current values live in `src/shared/GameConfig.lua`.

- Run duration: `RunDurationSeconds`
- Death penalty: `DeathPenaltySeconds`
- Respawn safety: `RespawnGraceSeconds`
- Warden damage: `Config.Warden.Damage`
- Warden attack range/cooldown
- Warden stage speeds and detection ranges

Change one variable at a time after a full test run so it is clear what improved or worsened the experience.
