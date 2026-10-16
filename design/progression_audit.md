# Progression and sequence-break audit (Beta 1.5.0)

Written 2026-10-15, after the last content update. The user played the whole game and found that some next steps weren't clear. This file covers how every main step is now signposted in the world, what gates each one, and what was found and fixed.

## How the next step is shown (no journal needed)

Every main-quest step from Chapter I to the end has all of these:

| Layer | Where | How |
|---|---|---|
| **Spoken** | Whoever ends a beat says where to go next, and repeats it when spoken to again (Rowena, Maud, Lothelye, Pip...) | Story scenes and NPC lines |
| **Rumor** | Every townsperson in the houses and the market: every second conversation is the talk of the day | `scripts/npc/gossip.gd` (TALK, keyed by the step's condition) |
| **Herald** | Pip by the Castle Town fountain (in Himeko's palace during the fall, in the refuge during the war) cries the news | `Gossip.news()` |
| **Guiding light** | Out in the open, a column of pale gold light at the exit to take next, or at the door of the goal itself (shortest road over `WorldData.ROADS`) | `scripts/systems/guide.gd` (GOALS); OPTIONS > GUIDING LIGHT |
| **Opening shots** | When the story opens a way somewhere else, the camera shows it the first time you come back | `Guide.PANS` |
| **First views** | The first time you enter a great region, the camera looks out to its dungeon | `StoryBeats.VISTAS` |
| **Goddess voices** | Each bun piece: the goddess points to the next piece | `StoryBeats.bun_piece` |

`test_gossip_covers_main_steps` fails if any main step lacks a rumor or a goal, or if a goal isn't a real place. `test_guide_beacon` checks the routing.

## Gates, step by step (main story)

| Chapter | Gate | Opened by | Guidance |
|---|---|---|---|
| I | Lake Shrine | free | Pip (the summons), the vista, rumors |
| I | the goddess towers | free (each tower's own puzzles) | lake_done scene, goddess voices, vistas |
| I | the pedestal | the three bun pieces | Aphiel's voice, rumors |
| I | the castle | the takeover (`castle_fallen`) | scenes |
| II | Frostpeak Hollow | the frozen falls: the Iron Mallet | Aladriel, rumors |
| II | the Sun Trial | the great stone: the Bun Bracers | Aladriel, rumors |
| III | the road east | the sandstorm: `ch2:trail_found` | an opening shot |
| III | the crypt | the gate: `ch3:confession` | Maud, an opening shot |
| IV | the Dark Forest | the brambles: `ch4:grove_known` | an opening shot |
| IV | the Temple of Bun | dig: the Grave Spade | Wren, rumors |
| IV | the Citadel | `ch4:astral_seal` (WorldData.resolve) | scenes |
| V | the Barrow | the chapel doors: `ch5:barrow_open` | an opening shot |
| V | Cinderhold | the great stone: the Questlord's Gauntlets | rumors |
| V | the Ridge | the black water: `ch5:ridge_open` | the part_water scene |
| V | Ridge Keep | the chains: `ch5:camps_done` | the camps_broken scene, an opening shot |
| V | the Sanctum Ruin | `ch5:rift_seen` (resolve) until `ch5:velloran_done` | Rowena (rift_seen) |
| V | Lothelye's spring | the Dream scene needs `ch5:velloran_done` | Lothelye's voice |
| V | the Rift's mouth | `ch5:rift_open` (needs `ch5:dream`) | Lothelye, an opening shot |
| V | the Rift's drifts | the star locks (1 -> 2F, 2 -> 3F, 3 -> 4F, 4 -> the heart) | each lock's camera shot |
| V | the heart | the dream stair (needs the Dream) and the boss key | the hub's plaque |

Order-critical items are always gained before they are needed:
- The Dream comes before the Rift opens.
- The Gauntlets come before Cinderhold.
- The Starfall Arrows come before the Citadel, Velloran and phase 1.
- The Hookshot (Chapter I) comes before the Rift's hook rooms.
- The Sapphire Staff (Chapter IV) comes before the fire walk.
- The Flail comes before the bells.

## Found and fixed in this pass

- **Astral Rift pits.** Four puzzle rooms first had solid strips round their pits, so the tool could be skipped. The pits now run wall to wall (`astral_rift.gd pits()`):
  - the mirror shore: only the Hookshot crosses;
  - the drowned shrine: the switch must be hit from across;
  - the hook band: the Hookshot again;
  - the gale walk: one strip, with the wind blowing toward the pit;
  - the starfield: a dream maze with a landing at each door.
- **The Ridge's Rift mouth** is a proper exit. It is gated (`AreaExit.need_flag`, `hide_flag`) and gone after the ending.
- **The Sanctum** sends you to its ruin only during the Order's last stand, then back to the real Sanctum.
- **The prologue** loads the Cinder Vault but no longer marks it visited, which used to tick a Chapter V journal step and the map.

## Geometry audit (tests/geometry_audit.tscn)

New and changed areas: astral_rift, sanctum_ruin, black_water_ridge, every Castle Town variant, village, village_refuge, batela_fells, lake, hero_house and sample houses. Result: **1 report, a false positive.** The Rift's mouth is gated until `ch5:rift_open`, so the audit's hero can't enter it.
- All 29 Castle Town doors work.
- All 10 village doors work.
- All 4 Fells doors work.
- Every house's way out works.

The audit of every area in the game is in `_giggle64_work/tmp/audit_all15.log`.
- Field: a bomb boulder "stands side-on" in front of a cliff cave (107, 60). This is not a break: the cave's Piece of Heart only appears once the boulder is bombed (its flag), so walking round it gets nothing.

- **Snow (Frostpeak): fixed.** The ice sheet over the frozen falls could be walked past at its side, which let you into Frostpeak Hollow (Chapter II) without the Iron Mallet. The cave's way in now stays shut until the ice is broken (`snow:falls_broken`), and the sheet is wider.
- Desert: the road to the Dark Forest can't be entered. This is expected: the brambles close it until `ch4:grove_known`.

- Dark Forest: the earth over the buried stair can be stepped past. This isn't a break: the temple door itself waits on `ch4:temple_found` (dug with the Grave Spade).
- Field (war): the goblin war camps' barricades can be walked round. That's cosmetic, since breaking the camps is the objective itself.
- Cave boulders in the forest and Southern Fields: the same as the field's (the prize appears only once bombed).

## Journal gap found

- The **Bog Tower** (Bloom Rod) was part of Chapter I in the masterplan, and the castle needs the Bloom Rod (its cistern pit), but the journal went straight from the towers to the sword. It now has a step ("Find what the Bog Tower hides, out in the West Marshlands.") with its own rumor, herald news and guiding light, and Aphiel points to it.

## Second sweep (Beta 1.5.1, 2026-10-15)

A full re-check of every gate after the last content update. The geometry audit now models climbing:
- `--climb`: the fill climbs ledges up to the jump-grab height (LEDGE_PROBE, 3.33 m) and drops from any height;
- `--only=selftest`: checks that fill;
- `--only=reach`: point to point.

That exposed climb-overs the old walking fill never saw.

Found and fixed:
- **Westmarch gate** (field/field_war): opened on `ch4:war`, so the camps and the siege could be skipped. Now `ch4:siege_won`.
- **Batela crypt mouth**: its 2.6 m walls could be jump-grabbed to drop in behind Maud's gate. The walls are now no_climb, and the door also needs `ch3:confession`.
- **T-junction perches**: the end of a 0.4 m wall where another meets it passed the ledge probe's depth check (Sapphire Sanctum cells, Westmarch cells).
  - Fixed for the whole game in `PlayerController._probe_ledge`: the top must also reach PERCH_HALF_WIDTH (0.25 m) to either side.
- **Cinder Vault** (ore room walls, frost hall ice walls) and **Ridge Keep** (cistern walls): 3 m walls beside Ember Rod gates. Now no_climb.
- **Rowena**: the camps could be broken before meeting her, which left the journal on step 1. Now siege_begins sets `ch4:captain_met`, and she has an intro that thanks him for the camps.

- **The sandstorm** (desert -> Forest of the Dead): 14 m wide on a corridor whose walkable banks make 20 m (`region.gd`: floor `w`, banks `wall` 5 m). It was walked round from a new file, confirmed with the real hero (`--only=walk`). Now 26 m wide. The brambles are 24 m wide and 10 m tall.
- **The marsh thicket** (marsh -> Black Water Ridge): waded round at its ends, because the marsh water runs on past them. It is now 32 m wide, plus a second seal at x -55.5 (24 m wide, 16 m tall) where the corridor narrows between the rims.
- **The cliffs' great stone**: the Gauntlets are won mid-Barrow, so the pass could be opened before the Hollow King. `GreatStone.need_flag` is now `ch5:barrow_done`, with a wait_text.
- New audit mode `--only=gates [--flags=a,b] [--noclimb]`: one climbing fill over a whole region from its spawn, listing every exit reached.
  - Its water is pessimistic (it treats pool beds as floor). The marsh islet and the Bog Tower moat show as reached, but `--only=walk` proves the swimmer is stopped short.
  - Exits gated in the no-flags state (sandstorm, brambles, marsh seal) now also show in the plain exits audit as "could not run into it". That is expected.

Re-checked, still sound:
- `--only=routes`: no locked door in any dungeon can be got round.
- The plain audit and the climb audit leave only the known false positives above: side-on boulders, the war camps, the Dark Forest mound, the brambles' exit and the Rift mouth.
- The castle cistern pit (Bloom Rod) holds, checked with `--only=reach`.
- Item sources against their gates (mallet, bracers, gauntlets, spade, Ember Rod) are in order.
- Biscuit's jumps (up to 2.16 m) can't clear any story barrier (3.2 m and up).
- The Hookshot bites only on hookable targets; bombs only hit bombables.
- Cutscene skip only fast-forwards; saves, waystones and CONTINUE all resolve() the area.

Missables in closing areas. The user asked for catch-ups, and they are BUILT (`scripts/npc/catch_up.gd`, CatchUp; test_catch_ups_after_peace). After `ch4:peace`:
- Rowena (rebuild_lines, knights_lines): sets every `rescue:*`, gives all unclaimed garrison rewards, and gives chart_2.
- Pink (PinkLines): gives the Longshot (if the hero has the Hookshot), chart_6, and the castle Piece of Heart (sets `castle:heart_piece`).
- Posy (rebuild_lines, chapter5_lines): if `pepper:asked` and not rewarded, closes the quest and gives the purple rupee.

The original list:
- the Citadel (closes at `ch4:sealed`): the Longshot (not needed later; the base Hookshot reaches 7.8 m and the Rift's gaps are about 5.7 m) and chart scrap 6;
- the war-time field and refuge (close at `ch4:peace`): chart scrap 2 in a camp chest, the field's garrison soldiers and Rowena's garrison rewards (a Piece of Heart at 6), and Pepper;
- the castle (sealed after `ch4:peace`): the oubliette's Piece of Heart.
