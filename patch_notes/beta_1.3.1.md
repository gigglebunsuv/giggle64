# Beta 1.3.1 — True N64

A patch with more of Ocarina of Time's moves, a new waystone menu, a new graphics option that draws the game the way an N64 would, and an OST update.

## Movement (more of Ocarina of Time)
- **Swap items while aiming**: with the bow drawn in first person, press the Grapple Hook's button and the hero puts the bow away and brings the Grapple Hook up. The view and your aim stay where they were. This works between the bow, the magic arrows, the Grapple Hook, the Boomerang and the Bloom Rod. An item you don't aim (a bomb, a bottle...) takes you out of first person and is used as usual.
- **Grapple Hook while locking on**: the Grapple Hook now comes out without leaving the third-person view and fires straight at whatever you're locked on to, just like the bow. Swap between the bow and the Grapple Hook without letting go of Z.
- **Landing roll**: when falling from a height, hold the stick forward as you land to roll out of it.
- **Fall damage**: a long fall now hurts. A drop of about 12 m costs half a heart and twice that costs a heart, with a hard landing. Rolling out of the landing saves you, unless the drop was very high.
- **Slippery slopes**: ground marked as slippery makes you slide to the bottom, and you can't run back up it. Only marked ground slides, as in Ocarina of Time. Ordinary hills and the steep paths of the Northeastern Cliffs are as they were.
- **Quickspin**: once you've learned the Great Spin, swirl the stick and press **B** for an instant spin without charging.
- **Camera**: the camera now tilts with the ground ahead. It looks down as you go downhill or reach a drop, and up as you climb. It also eases smoothly when you swap items in first person.

## The Waystone menu
- Touching an awakened waystone now opens a **map of pictures**: every waystone's region in a grid. Stones you haven't found yet are dark and marked **???**, and the one you're at is marked HERE.
- Move with the stick, the arrows or the mouse. Press **A** to travel and **B** to stay.

## New graphics option: TRUE N64 MODE
Find it under **OPTIONS > GRAPHICS** (off by default). It draws the game the way the N64's hardware would:
- **Textures** are filtered with the N64's **3-point (triangular) filter**, which gives its hexagonal blur rather than modern bilinear. They're stored as 16-bit color, and limited to the 64×64 that the N64's 4 KB texture memory held. The painted ground of each area keeps its full size.
- **16-bit color** with the N64's ordered dither, then the video chip's dither filter, which hides most of the pattern and leaves a faint trace of it.
- **Soft, low-resolution edges** and the video chip's slight horizontal blur: the hazy, soft N64 picture.
- The picture stays at **240 lines**, with per-vertex (Gouraud) lighting.
- **N64 MIPMAPS** (only with TRUE N64 MODE): textures blend toward a half-size copy as they shrink into the distance, like the N64's 2-cycle mode.

## Music
- The OST album has 15 new tracks: all of Chapters IV and V so far, the end credits, and a hidden bonus track, *Age of Enlightenment*. That makes 44 tracks in all.
- **Avalon's theme** is written (MIDI): A major / D Lydian, on her motif, with the Pachelbel canon as her second motif. It's for her scene in the Astral Dimension, near the end of the game.

## Fixed / changed
- The OPTIONS > GRAPHICS list has the two new rows. While TRUE N64 MODE is on, RESOLUTION shows 240P (N64).
