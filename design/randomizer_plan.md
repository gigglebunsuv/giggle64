# Randomizer: plan (not built)

Written 2026-10-16, after beta 1.7.0. This is a plan only. Nothing here is built yet.

## The idea

A file mode in the style of the OoT Randomizer: the items in chests, Heart Shards, gifts and shops are shuffled from a seed, so every run is a new route through the same Bunsriel.

The seed is always **beatable**. A logic checker proves that every item you need can be reached in some order before it is handed out.

Most of the hard parts already exist:
- story and gate **flags** for every lock in the game;
- the climb-aware **geometry audit**, `tests/geometry_audit.tscn` with `--only=gates` and `--only=reach`, which already answers "what can the hero reach with these flags?";
- `HeartShards.SOURCES`, `CatchUp` and the progression audit, `design/progression_audit.md`.

## What gets shuffled

| Pool | Count (about) | First version |
|---|---|---|
| Major items (Boomerang ... Ember Rod, 28-slot grid) | 28 | yes |
| Swords, shields, tunics, boots, upgrades (quiver, bomb bag, wallet, scale, bracers) | ~25 | yes |
| Heart Shards and Heart Vessels | 28 + ~12 | yes |
| Bottles | 4 | yes |
| Dungeon Small Keys, Boss Keys, Maps, Compasses | ~90 | option: in their own dungeon (default) / anywhere ("keysanity") |
| Coins and ammo chests | ~120 | filler |
| Goddess Spring blessings, Knight's Techniques | 5 + 4 | later (they're taught in scenes) |

These stay fixed:
- the Bun Sword's three pieces (the legend scene needs them);
- story items handed over in cutscenes, such as the Astral Seal and the Starlight Lantern, in version 1.

## How it works in the game

1. **Seed and settings.** The file select gets a **NEW RANDOMIZER FILE** button. It opens a short settings page (keysanity, skip cutscenes, open story, starting items) and a seed, either typed or random.
   - The file stores `seed`, `settings` and the shuffled **placement table**, with SAVE_VERSION bumped to 3.
   - The file select shows a 5-icon **seed hash**, drawn from the item icons, so two players can confirm they have the same seed.
2. **Swapping items.** Every check already has a unique flag (`<area>:chest_x`, `heart_piece` flags and so on). `GetItem.give()` and `TreasureChest` look the flag up in the placement table and give the mapped item instead. One small hook covers chests, NPC gifts (`Npc.gifts`), shops, and freestanding Heart Shards.
3. **The story.** The chapters are tightly scripted, so version 1 shuffles **within each chapter**. Items from Chapter III can't land in Chapter I, so every story flag stays valid. An **OPEN STORY** setting (version 2) sets the chapter flags up front and opens the sealed entrances (Westmarch, the Fells, the Ridge), for a full shuffle.
4. **Hints.** Gossip (`scripts/npc/gossip.gd`) already speaks "the talk of the day". In randomizer files, townsfolk can give hints instead, OoT gossip-stone style, such as "They say the Grapple Hook rests in Bog Tower."
5. **The spoiler log.** A text file written next to the save, listing every location and its item, in sphere order.

## The logic

- `design/randomizer_logic.json` holds each location and its requirement, written as items or flags combined with and/or.
- It's seeded automatically: for each location, run the geometry audit's reach fill with the minimal flag set. Then add item requirements by hand where the audit can't see them (switches, bombable walls, grapple targets, lantern-lit rooms).
- **Assumed fill.** Place progression items in reverse, each one into a location that's reachable assuming everything not yet placed is already owned. Then scatter the filler.
- **Verification.**
  - Every generated seed is replayed by the solver in spheres (sphere 0 = what's reachable from the start).
  - A CI-style test generates 500 seeds and fails if any of them is unbeatable.
  - A smoke test drives the real hero through the first few spheres of fixed seeds with the `--only=walk` driver.

## Phases

1. **Plumbing:** the placement table, the swap hook, saving, the seed hash, the spoiler log. With a "vanilla" seed (the identity map), the existing test suite must still pass.
2. **Chapter-locked shuffle** of majors, gear and Heart Shards, with the solver and the 500-seed test.
3. **Keysanity, hints and starting-item settings.**
4. **OPEN STORY:** the full shuffle, with cutscene skips for randomizer files.
5. **Optional:** an entrance shuffle of dungeon doors. This needs changes to `World.resolve`.

## Questions for you

1. Should randomizer files award the file star and count toward completion?
2. Ship it with 1.0, or as a 1.1 update after release?
3. Should the hints be cryptic (OoT style) or plain?
