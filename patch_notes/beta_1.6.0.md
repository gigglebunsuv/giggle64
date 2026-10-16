# Beta 1.6.0 — The Cutting Edge

An animation overhaul. Gigglebuns now fences the way Ocarina of Time's hero does, with a different cut for every stick direction and lock-on. His blade finally cuts with its edge. The skeletons and the armored knights move with weight instead of sliding about stiffly. Every animation in the game, people and creatures alike, now flows from pose to pose instead of moving in straight lines between them. The game's words have changed too: the borrowed Zelda names have been replaced with its own, and the text is in American English throughout.

## Swordplay
- **The cut follows the stick and the lock-on**, as in Ocarina of Time (`func_80837818`):
  - **Standing still**: a forehand cut across, right to left.
  - **Running**: a diagonal chop down from the right shoulder.
  - **Locked on, stick still**: the chop.
  - **Locked on, stick forward**: a **thrust** that lunges in.
  - **Locked on, stick to the left or right**: a cut sweeping that way (the forehand, or the backhand from left to right).
- **Combos and finishers.** Keep pressing B and the cuts chain on, each one picking its direction afresh from the stick. The **third cut of the same kind in a row is a finisher**, a bigger blow that steps in, winds up further, swings wider and knocks foes back harder (OoT's `*_kiru_finsh`). The heavier swing sound gives it away.
- **He cuts with the edge, not the flat.** In the horizontal cuts his forearm rolls a quarter turn so the blade lies level and its edge leads, and the chops come down edge first. The Great Spin now sweeps edge first too. Every cut was measured: the flat used to lead about 97% of the time in a level swing; now it is the edge, in every cut.
- **The slash from the saddle and the stab from behind the shield** are now real swings on his arms and chest over whatever his legs are doing, instead of a single pose snapped in and out.
- The blade's reach now fits the cut: a narrow, long line for the thrust, a wide sweep for the level cuts, a tall strip for the chop.

## Gigglebuns moves better
- **New run and walk.** Eight poses a stride instead of two to four: the heel strikes, the knee gives under his weight, the foot pushes off, and the swinging leg folds up and reaches through. The run leans into it, pumps the arms and leaves the ground between steps.
- **Running with the sword out** has its own stride: the blade stays low and level at his side instead of pumping up past his face.
- **Standing**, he breathes and lets his weight drift from foot to foot.
- **The lock-on side-step** is a real step-and-close, with his sword held out toward the foe.
- When the jump-grab reaches for a ledge, his arms now swing forward and up, where they used to swing up behind his back.

## The foes move with weight
- **Skeletons** (all of them: the Lake Shrine's, the frost, bog and charred kinds, and the Barrow's knights):
  - they fence on bent knees, bouncing lightly, the blade up and the shield out;
  - they **side-step properly** as they circle you (they used to slide sideways standing still);
  - they wind up over the right shoulder before a fast cut that leads with the edge;
  - the leaping chop crouches, springs, raises the blade overhead and drives it down;
  - beaten, they fold down into their bones.
- **Tide Knights** (and every armored knight built on them: the Rust, Frost, Mire, Sapphire and Ember lines, the Sentinel and the wardens):
  - a heavy plod that rolls the hips over each planted foot;
  - the overhead chop gathers, heaves the cleaver up behind the head and holds it there, trembling, before it falls edge first;
  - the cleaver bites into the floor and the knight wrenches it free;
  - the sweep winds the whole body round, then swings through with the edge leading, not the cleaver's back;
  - turning on the spot, a knight now shuffles its feet instead of walking in place.
- **Every other animation** in the game (townsfolk, horses, bosses, creatures) eases from pose to pose now. Holds stay still and feet never dip through the floor.

## A new credits theme
The staff roll has a new score, and it carries every theme the game has been given. The credits tour visits each place as its theme plays:
- **Dawn over the fields:** the celesta remembers the first bar of the main motif.
- **Haven:** the **main motif** on the flute.
- **Castle Town and Mirror Lake:** the main motif "at home" in G major.
- **The Bun Sword's pedestal:** **Avalon's motif** over her second motif, **the canon**.
- **Ashwick:** the **Firebuns figure** in a major key, at peace.
- **A candle for Firebuns II:** the same figure slowed on the cello.
- **Black Water Ridge** (C minor):
  - the **Black Water Ridge motif**;
  - under it, the riff of **Age of Enlightenment**, by Water on Red;
  - **Mara's theme**, her root-to-fourth over a driving snare.
- **The Northeastern Cliffs:** Firebuns III's figure one last time, then the lift into E major.
- **The finale:** the main motif in triumph; then Avalon's motif with the **Ridge motif turned heroic**.
- **The coda:** Mara's root-to-fourth comes back on the cello, and this time it resolves.

The tour now has a twelfth stop (the cliffs at dawn), and every place and name card has been retimed to the new music (3:28).

## New names
Creatures and items borrowed from the Zelda games now have names of their own. Saves carry over unchanged.

| Was | Now |
|---|---|
| Rupees | **Coins**, now real coins on screen too |
| Stalfos | **Skeletons** |
| Keese (Fire, Ice) | **Cave Bats** (Fire Bats, Ice Bats) |
| Tektites | **Hoppers** |
| Leevers | **Sand Spinners** |
| Octoroks | **Rock Spitters** |
| Freezards | **Frost Idols** |
| Hookshot / Longshot | **Grapple Hook** / **Long Grapple** |
| Piece of Heart / Heart Container | **Heart Shard** / **Heart Vessel** |
| Mirror Shield | **Silvered Shield** |
| Z-Target (option) | **Lock-On** |

## American English
All of the game's text is now in American spelling: color, armor, gray, center, meter, defense, and so on. The Gaoler of Ridge Keep is now **the Jailer**. A few British turns of phrase are gone from the dialogue too: Mum is Mom, biscuits are cookies, and Clover no longer asks if you "fancy" a round.

## Under the hood
- `tools/gen_characters.gd`:
  - every animation track is resampled at 30 Hz along a monotone cubic through its keys (`_smooth_keys`), so nothing overshoots;
  - `_pose_anim` builds an animation from whole poses;
  - `_sword_anims` holds the eight cuts.
- `PlayerCombat.SWINGS`: each cut's timing, reach, step and knockback. `PlayerController._melee_kind` picks the cut.
- `CharacterModel.play_upper`: a third animation layer, a whole animation on chosen joints.
- New tests:
  - test_swing_kinds_follow_stick
  - test_cuts_lead_with_the_edge (measures the blade's edge against its path for the hero, the skeleton and the knight)
  - test_stalfos_strafes_in_step
  - test_upper_body_cut_over_the_saddle
