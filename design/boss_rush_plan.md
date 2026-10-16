# Boss Rush and speedrun support: plan (not built)

Written 2026-10-16, after beta 1.7.0. This is a plan only.

## The Questlords' Arena (post-game)

After the true ending (`game_complete`), Idrith and Aladriel open a sparring ring.
- **Where:** on the Ladhellin desert's edge, by Serielye's Spring. The Questlords are heroes of Ladhellin, and it gives the post-game a place to go.
- **What happens:** Aladriel offers trials, Idrith keeps the record board, and the Questlords' banter sets each trial up ("We'll face this together, always").

### Trials

| Trial | Fights | Unlocks |
|---|---|---|
| Chapter I | Carapax, Corvax, the Mummy Lord, the Wyvern, Gullagog, Firebuns III (castle) | the arena opens |
| Chapter II–III | the Frost Idol keeper, the Sun Trial guardian, Incunax, the Batela duel | Chapter I cleared |
| Chapter IV–V | the siege ogre, the Cinder Wyvern, Magmaw, the Hollow King, the Jailer, Mara | Chapter II–III cleared |
| **The Gauntlet** | every boss in order, ~20 fights | all three cleared |
| Finale | Velloran, then the three-phase Firebuns III | the Gauntlet cleared |

(The exact boss list comes from the `bosses` group across the dungeon scenes. This table is the intent.)

### Rules

- **Loadout:** your file's gear, or a fixed "tournament" kit (an option per trial, OoT Boss Challenge style).
- **Between fights:** a short rest room with a heart refill (a fairy fountain) and a door to the next fight. No saving mid-trial.
- **Intros:** shortened to the title card (`Cutscene.boss_intro` gets a "rush" flag that skips the walk-in).
- **Reuse:** each fight loads the boss's own arena scene with a `rush` entrance.
  - `World.resolve` returns to the arena afterward instead of to the dungeon's blue warp.
  - Rewards and story flags are not given in rush mode.
- **Records:**
  - The best time for each trial is kept per file, and the best of all files in the settings file.
  - Idrith's board shows them, and the file select shows a small trophy next to the star.

## Speedrun support (any file)

- **OPTIONS › SPEEDRUN TIMER:**
  - In-game time on the HUD, in the corner opposite the minimap.
  - It counts in 1/60 s from `Progress.play_time`, which already exists, and pauses on loads, like the community IGT rules.
- **Splits:** automatic splits at each dungeon's boss kill and each chapter card, shown for a few seconds under the timer.
- **Autosplitter hook:** each split is also written to `user://splits.log` with a timestamp, so LiveSplit (via a simple script component) or OBS can follow along.
- **Cutscene skip:** START already skips seen scenes. A **FAST TEXT** option makes text appear instantly.
- **Seeded RNG option:** enemy patterns and drops run from a fixed seed per room entry, for practice.

## Phases

1. The timer, splits and fast text: small, and useful to your playtesters too.
2. The arena area, the Questlords' lines and the Chapter I trial.
3. The other trials, the Gauntlet, records and trophies.
4. The tournament kit option and the seeded RNG.

## Questions for you

1. Put the arena in Ladhellin, or somewhere else, such as a ring behind Pink's Armory?
2. Should the Gauntlet trial give a reward (a title on the file, a golden Bun Sword skin)?
3. Should the speedrun timer be visible to everyone, or only after the game is finished once?
