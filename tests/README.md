# Tests and verification tools

All commands assume `GODOT` is the Godot 4.7.2 executable and that you run them from the project folder.

## Automated gameplay tests (headless)

`-- --tests=test_a,test_b` runs only the named tests.

```
GODOT --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
```

The runner loads a fresh copy of `scenes/main.tscn` for each test and drives it with simulated input. The exit code is 0 when every test passes.

Coverage:
- **Startup and rendering:** 320×240 viewport, nearest upscale, uniform scale.
- **Title and file select:** the splashes skip with A, the title hides the hero, START opens the file select, a file opens the area list, B backs out, and choosing an area starts play there.
- **Movement:** normalized diagonals, jump and gravity, collision, the OoT stick curve, instant standing starts, stop-and-reverse, roll, lock-on side hop and back flip, ledge auto-jump.
- **Input and settings:** gamepad stick and buttons, 21 fps mode keeps the same running speed.
- **Camera:**
  - mouse never rotates it
  - turning around keeps the camera still
  - Shift recenters it
  - 3 s idle auto realign, which never rotates the player
  - movement cancels realign and resets the idle timer
  - no jitter while idle
  - wall collision
- **Combat:**
  - one hit per swing
  - two-hit combo, enemy death and cleanup
  - the cut follows the stick and the lock-on, and the third in a chain is a finisher
  - every cut (the hero's, the skeleton's, the knight's) leads with the blade's edge
  - the saddle slash plays on the upper body over the riding legs
  - frontal block versus rear hit
- **Enemy AI:**
  - detect, chase, telegraph and attack
  - cooldowns
  - a blocked attack stuns the enemy
  - the skeleton circles with its own side-step, not its idle pose
- **Targeting:** separate from camera recenter.
- **Player:** death and respawn, fall-out recovery.
- **Pause:** blocks gameplay input; the pause screen opens, flips pages with R/Z and closes; Back/M toggles the minimap.
- **Climbing:**
  - hop up a 1 m block
  - the short and tall step-ups
  - jump, catch and climb a 3 m ledge
  - hang and drop with A
  - walking slowly off an edge hangs; running off still jumps
  - walls over 3.3 m and thin rails are not climbed
  - A-only blocks
  - ladders up and over the top, and down from the top
  - the ladder to Mira's roof deck
- **First person and the bow:**
  - the look view: eyes, turning, leveling, mouse
  - the inverted option
  - draw, hold, release, the next arrow, B to put it away
  - arrows stick in walls and hurt enemies
  - the Z-target bow
  - no arrows / empty button
  - arrow bundles
  - equipping from SELECT ITEM
  - the new button layout (RB look, X / Y items)
- **Talking:**
  - text box opening, typing, skipping and a two-choice branch
  - Mira's door in and out
  - talking to Mira
  - every one of her boxes fits
- **World map:**
  - the picture exists
  - every region has a dot
  - a house maps to its region
- **Overworld:**
  - every exit lands on a matching entrance in an existing area, and has a way back
  - the hero stands on solid ground at every entrance
  - walking into the field's north exit loads Old Castle Town with a fade, the title card and the same health
  - deep water voids out

## Screenshot capture (windowed, needs a GPU)

```
GODOT --path . --resolution 1280x960 res://tests/visual_capture.tscn -- --automation --title --out=<absolute folder>
```

This plays a short scripted sequence and saves the raw 320×240 frames and full-window images.

## Overworld and pause screen captures (windowed)

```
GODOT --path . --resolution 640x480 res://tests/world_capture.tscn -- --automation --out=<absolute folder> [--areas=field,village] [--quick]
GODOT --path . --resolution 640x480 res://tests/pause_capture.tscn -- --automation --out=<absolute folder>
GODOT --path . --resolution 640x480 res://tests/feature_capture.tscn -- --automation --out=<absolute folder>
```

`world_capture` saves, for each area:
- the view from every entrance
- a few seconds of running
- fog-free overviews from the north and south

`pause_capture` saves:
- the minimap
- the pause screen opening
- each page
- a page flip in progress
- the world map and the area map

`feature_capture` saves:
- Mira's house, its door and ladder, the ladder climb and the roof deck
- the archery targets, aiming, an arrow in flight and stuck
- the first-person view
- inside the house, and three moments of talking to Mira
- hanging from a ledge and climbing up
- the world map and SELECT ITEM pages

The combat and movement tests run in the test area; the overworld tests load the field.

## Title and file select captures (windowed)

```
GODOT --path . --resolution 640x480 res://tests/title_capture.tscn -- --automation --out=<absolute folder>
```

This saves both splash screens, the start and end of every title backdrop shot, the title, the file select and its area list, and the game starting in the chosen area.

## Model contact sheets (windowed)

```
GODOT --path . res://tests/model_preview.tscn -- --out=<absolute folder>
```

This renders the hero, the Cinder Goblin and Mira in key animation poses, at 320×240 per frame, plus the hero's climbing, ladder and bow poses and close-up portraits.

## Geometry audit (headless)

```
GODOT --headless --path . --fixed-fps 60 res://tests/geometry_audit.tscn -- [--areas=a,b] [--only=blockers|exits|doors|routes|enemies|climb|swim|fall]
```

- **blockers**: every lock, bar, seal, boulder, great stone, thorn and ice wall: the ground round it is flood-filled with the hero's capsule; any the fill gets past is reported.
- **exits**: the hero runs from each exit's return spot into its loading zone.
- **doors**: in front of every door, A must take him through.
- **routes**: from one side of each locked door the whole dungeon is flooded (climbing and dropping storeys); reaching the far side is a way round it.
- **enemies**: every dungeon creature starts on a floor, out of walls and inside its room.
- **climb / swim / fall**: stepping stones climbed out onto from water and sludge, and real drops measured for fall damage.

## Bug-fix update captures (windowed)

```
GODOT --path . --resolution 640x480 res://tests/bugfix_capture.tscn -- --automation --out=<absolute folder> [--only=entrances,arrival,chest,caves,bombs,pause,sword,hearts] [--areas=a,b]
```

